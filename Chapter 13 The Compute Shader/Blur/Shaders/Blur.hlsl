//=============================================================================
// Performs a separable Guassian blur with a blur radius up to 5 pixels.
//=============================================================================

cbuffer cbSettings : register(b0)
{
	// We cannot have an array entry in a constant buffer that gets mapped onto
	// root constants, so list each element.  
	
    int gBlurRadius;

	// Support up to 11 blur weights.
    float w0;
    float w1;
    float w2;
    float w3;
    float w4;
    float w5;
    float w6;
    float w7;
    float w8;
    float w9;
    float w10;
};

static const int gMaxBlurRadius = 5;
static float sigma_s = 2.5f;
static float sigma_r = 0.08f;

Texture2D gInput : register(t0);
RWTexture2D<float4> gOutput : register(u0);

#define N 256
#define CacheSize (N + 2*gMaxBlurRadius)
groupshared float4 gCache[CacheSize];

struct WeightData
{
    float weights[11];
};

WeightData CalculateBFWeight(int ID)
{
    WeightData ans;
    float weight_sum = 0.f;
    float sigma_s = 1.f;
    float sigma_r = 0.1f;
	
	
    for (int i = -5; i <= 5; ++i)
    {
        int ori_index = ID + 5;
        int tar_index = ori_index + i;
		
        float space_diff = i;
        float range_diff = gCache[ori_index].x + gCache[ori_index].y + gCache[ori_index].z - gCache[tar_index].x - gCache[tar_index].y - gCache[tar_index].z;

        float temp1 = -pow(space_diff,2);
        temp1 /= (2.f * sigma_s * sigma_s);
        
        float temp2 = -pow(range_diff, 2);
        temp2 /= 0.001;
        
        float w = exp(temp1 + temp2);
        weight_sum += w;
		
        ans.weights[5 + i] = w;
    }
	
    for (int j = 0; j < 2 * 5 + 1; j++)
    {
        ans.weights[j] /= weight_sum;

    }
    return ans;
}

[numthreads(N, 1, 1)]
void HorzBlurCS(int3 groupThreadID : SV_GroupThreadID,
				int3 dispatchThreadID : SV_DispatchThreadID)
{
	// Put in an array for each indexing.
	//float weights[11] = { w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10 };
	//
	// Fill local thread storage to reduce bandwidth.  To blur 
	// N pixels, we will need to load N + 2*BlurRadius pixels
	// due to the blur radius.
	//
	
	// This thread group runs N threads.  To get the extra 2*BlurRadius pixels, 
	// have 2*BlurRadius threads sample an extra pixel.
    if (groupThreadID.x < gBlurRadius)
    {
		// Clamp out of bound samples that occur at image borders.
        int x = max(dispatchThreadID.x - gBlurRadius, 0);
        gCache[groupThreadID.x] = gInput[int2(x, dispatchThreadID.y)];
    }
    if (groupThreadID.x >= N - gBlurRadius)
    {
		// Clamp out of bound samples that occur at image borders.
        int x = min(dispatchThreadID.x + gBlurRadius, gInput.Length.x - 1);
        gCache[groupThreadID.x + 2 * gBlurRadius] = gInput[int2(x, dispatchThreadID.y)];
    }

	// Clamp out of bound samples that occur at image borders.
    gCache[groupThreadID.x + gBlurRadius] = gInput[min(dispatchThreadID.xy, gInput.Length.xy - 1)];

	// Wait for all threads to finish.
    GroupMemoryBarrierWithGroupSync();
	
	//
	// Now blur each pixel.
	//

    //WeightData Data = CalculateBFWeight(groupThreadID.y);
	
    float4 blurColor = float4(0, 0, 0, 0);
    float weight_sum = 0.f;
    
    for (int i = -gBlurRadius; i <= gBlurRadius; ++i)
    {
        int k = groupThreadID.x + gBlurRadius + i;
        int ori_index = k - i;
        int tar_index = k;
		
        float space_diff = i;
        float range_diff = gCache[ori_index].x + gCache[ori_index].y + gCache[ori_index].z - gCache[tar_index].x - gCache[tar_index].y - gCache[tar_index].z;

        float temp1 = -pow(space_diff, 2);
        temp1 /= 500;
        
        float temp2 = -pow(range_diff, 2);
        temp2 /= 0.005;
        
        float w = exp(temp1 + temp2);
        weight_sum += w;
		
        blurColor += w * gCache[k];
    }
    gOutput[dispatchThreadID.xy] = blurColor / weight_sum;
    //gOutput[dispatchThreadID.xy] = blurColor;
}

[numthreads(1, N, 1)]
void VertBlurCS(int3 groupThreadID : SV_GroupThreadID,
				int3 dispatchThreadID : SV_DispatchThreadID)
{
	// Put in an array for each indexing.
	//float weights[11] = { w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10 };
	
	//
	// Fill local thread storage to reduce bandwidth.  To blur 
	// N pixels, we will need to load N + 2*BlurRadius pixels
	// due to the blur radius.
	//
	
	// This thread group runs N threads.  To get the extra 2*BlurRadius pixels, 
	// have 2*BlurRadius threads sample an extra pixel.
    if (groupThreadID.y < gBlurRadius)
    {
		// Clamp out of bound samples that occur at image borders.
        int y = max(dispatchThreadID.y - gBlurRadius, 0);
        gCache[groupThreadID.y] = gInput[int2(dispatchThreadID.x, y)];
    }
    if (groupThreadID.y >= N - gBlurRadius)
    {
		// Clamp out of bound samples that occur at image borders.
        int y = min(dispatchThreadID.y + gBlurRadius, gInput.Length.y - 1);
        gCache[groupThreadID.y + 2 * gBlurRadius] = gInput[int2(dispatchThreadID.x, y)];
    }
	
	// Clamp out of bound samples that occur at image borders.
    gCache[groupThreadID.y + gBlurRadius] = gInput[min(dispatchThreadID.xy, gInput.Length.xy - 1)];


	// Wait for all threads to finish.
    GroupMemoryBarrierWithGroupSync();
	
	//
	// Now blur each pixel.
	//
    //WeightData Data = CalculateBFWeight(groupThreadID.y);
	
    float4 blurColor = float4(0, 0, 0, 0);
    float weight_sum = 0.f;
    float sigma_s = 2.5f;
    float sigma_r = 0.1f;
    
    for (int i = -gBlurRadius; i <= gBlurRadius; ++i)
    {
        int k = groupThreadID.y + gBlurRadius + i;
        int ori_index = k - i;
        int tar_index = k;
		
        float space_diff = i;
        float range_diff = gCache[ori_index].x + gCache[ori_index].y + gCache[ori_index].z - gCache[tar_index].x - gCache[tar_index].y - gCache[tar_index].z;

        float temp1 = -pow(space_diff, 2);
        temp1 /= 500;
        
        float temp2 = -pow(range_diff, 2);
        temp2 /= 0.005;
        
        float w = exp(temp1 + temp2);
        weight_sum += w;
		
        blurColor += w * gCache[k];
    }
    gOutput[dispatchThreadID.xy] = blurColor / weight_sum;
    //gOutput[dispatchThreadID.xy] = blurColor;
}

