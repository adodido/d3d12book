//***************************************************************************************
// color.hlsl by Frank Luna (C) 2015 All Rights Reserved.
//
// Transforms and colors geometry.
//***************************************************************************************

cbuffer cbPass : register(b0)
{
    float4x4 gViewProj;
    float gTime;
};

cbuffer cbPerObject : register(b1)
{
    float4x4 gWorld;
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
	
    float4 PosW = mul(float4(vin.PosL, 1.0f), gWorld);
    vout.PosH = mul(PosW, gViewProj);
	
    vout.Color = vin.Color;
    
    return vout;
}

float4 PS(VertexOut pin) : SV_Target
{
    return pin.Color;
}


