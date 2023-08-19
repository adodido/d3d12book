//***************************************************************************************
// color.hlsl by Frank Luna (C) 2015 All Rights Reserved.
//
// Transforms and colors geometry.
//***************************************************************************************
 
//cbuffer cbPerObject : register(b0)
//{
//	float4x4 gWorld; 
//};

cbuffer cbPerObject : register(b0)
{
    float w11;
    float w12;
    float w13;
    float w14;
    float w21;
    float w22;
    float w23;
    float w24;
    float w31;
    float w32;
    float w33;
    float w34;
    float w41;
    float w42;
    float w43;
    float w44;
};

cbuffer cbPass : register(b1)
{
    float4x4 gView;
    float4x4 gInvView;
    float4x4 gProj;
    float4x4 gInvProj;
    float4x4 gViewProj;
    float4x4 gInvViewProj;
    float3 gEyePosW;
    float cbPerObjectPad1;
    float2 gRenderTargetSize;
    float2 gInvRenderTargetSize;
    float gNearZ;
    float gFarZ;
    float gTotalTime;
    float gDeltaTime;
};

struct VertexIn
{
	float3 PosL  : POSITION;
    float4 Color : COLOR;
};

struct VertexOut
{
	float4 PosH  : SV_POSITION;
    float4 Color : COLOR;
};

VertexOut VS(VertexIn vin)
{
	VertexOut vout;
    
    float4x4 gWorld = float4x4(w11,w12,w13,w14,
                               w21,w22,w23,w24,
                               w31,w32,w33,w34,
                               w41,w42,w43,w44);
	
	// Transform to homogeneous clip space.
    float4 posW = mul(float4(vin.PosL, 1.0f), gWorld);
    vout.PosH = mul(posW, gViewProj);
	
	// Just pass vertex color into the pixel shader.
    vout.Color = vin.Color;
    
    return vout;
}

float4 PS(VertexOut pin) : SV_Target
{
    return pin.Color;
}


