//***************************************************************************************
// SobleFilter.h by Frank Luna (C) 2011 All Rights Reserved.
//
// Performs a blur operation on the topmost mip level of an input texture.
//***************************************************************************************

#pragma once

#include "../../Common/d3dUtil.h"

class SobelFilter
{
public:
	///<summary>
	/// The width and height should match the dimensions of the input texture to blur.
	/// Recreate when the screen is resized. 
	///</summary>
	SobelFilter(ID3D12Device* device, 
		UINT width, UINT height,
		DXGI_FORMAT format);
		
	SobelFilter(const SobelFilter& rhs)=delete;
	SobelFilter& operator=(const SobelFilter& rhs)=delete;
	~SobelFilter()=default;

	ID3D12Resource* Output();

	void BuildDescriptors(
		CD3DX12_CPU_DESCRIPTOR_HANDLE hCpuDescriptor, 
		CD3DX12_GPU_DESCRIPTOR_HANDLE hGpuDescriptor,
		UINT descriptorSize);

	void OnResize(UINT newWidth, UINT newHeight);
	CD3DX12_GPU_DESCRIPTOR_HANDLE OutputSrv();

	///<summary>
	/// Blurs the input texture blurCount times.
	///</summary>
	void Execute(
		ID3D12GraphicsCommandList* cmdList,
		ID3D12RootSignature* rootSig,
		ID3D12PipelineState* SobelPSO,
		ID3D12Resource* input);

private:

	void BuildDescriptors();
	void BuildResources();

private:

	ID3D12Device* md3dDevice = nullptr;

	UINT mWidth = 0;
	UINT mHeight = 0;
	DXGI_FORMAT mFormat = DXGI_FORMAT_R8G8B8A8_UNORM;

	CD3DX12_CPU_DESCRIPTOR_HANDLE mTmpCpuSrv;
	CD3DX12_GPU_DESCRIPTOR_HANDLE mTmpGpuSrv;

	CD3DX12_CPU_DESCRIPTOR_HANDLE mSobelCpuSrv;
	CD3DX12_CPU_DESCRIPTOR_HANDLE mSobelCpuUav;
	CD3DX12_GPU_DESCRIPTOR_HANDLE mSobelGpuSrv;
	CD3DX12_GPU_DESCRIPTOR_HANDLE mSobelGpuUav;

	Microsoft::WRL::ComPtr<ID3D12Resource> mTmpResource = nullptr;
	Microsoft::WRL::ComPtr<ID3D12Resource> mSobelResource = nullptr;
};
