texture tex0 < string name = "Base.tga"; >;	// Base texture
texture tex1 < string name = "Terrain.tga"; >;	// Terrain texture
texture tex2 < string name = "Color.dds"; >;	// Color texture
texture tex3 < string name = "Alpha.dds"; >;	// Terrain Alpha

float4x4 WorldMatrix;
float4x4 ViewMatrix;
float4x4 ProjectionMatrix;
float4x4 AbsoluteWorldMatrix;
float3	LightDirection;

sampler BaseTexture  =
sampler_state
{
    Texture = <tex0>;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler MapTexture  =
sampler_state
{
    Texture = <tex1>;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler ColorTexture  =
sampler_state
{
    Texture = <tex2>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler GeneralTexture  =
sampler_state
{
    Texture = <tex2>;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler TerrainAlphaTexture  =
sampler_state
{
    Texture = <tex3>;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    AddressU = Wrap;
    AddressV = Wrap;
};

struct VS_INPUT
{
    float4 vPosition		: POSITION;
    float3 vNormal			: NORMAL;
    float2 vAlphaTexCoord	: TEXCOORD0;
    float2 vProvinceIndexCoord  : TEXCOORD1;
};

struct VS_INPUT_BEACH
{
    float4 vPosition		: POSITION;
    float3 vNormal			: NORMAL;
    float2 vProvinceIndexCoord  : TEXCOORD0;
};

struct VS_OUTPUT_PASS0
{
    float4  vPosition : POSITION;
    float2  vTerrainTexCoord : TEXCOORD0;
    float2  vAlphaTexCoord : TEXCOORD1;
    float2  vBaseTexCoord : TEXCOORD2;
    float2  vColorTexCoord : TEXCOORD3;
};

struct VS_OUTPUT_PASS0_General
{
    float4  vPosition : POSITION;
    float2  vTerrainTexCoord : TEXCOORD0;
    float2  vAlphaTexCoord : TEXCOORD1;
    float2  vBaseTexCoord : TEXCOORD2;
    float2  vProvinceIndexCoord : TEXCOORD3;
};

struct VS_OUTPUT_PASS1
{
    float4  vPosition : POSITION;
    float3  vLightIntensity : TEXCOORD0;
};

struct VS_OUTPUT_BEACH_PASS0
{
    float4  vPosition : POSITION;
    float2  vTexCoord0 : TEXCOORD0;
    float2  vTexCoord1 : TEXCOORD1;
	float2	vColorTexCoord : TEXCOORD2;
    float3  vLightIntensityAndBeach : TEXCOORD3;
};

struct VS_OUTPUT_BEACH_PASS0_General
{
    float4  vPosition : POSITION;
    float2  vTexCoord0 : TEXCOORD0;
    float2  vTexCoord1 : TEXCOORD1;
	float2	vProvinceIndexCoord : TEXCOORD2;
    float3  vLightIntensityAndBeach : TEXCOORD3;
};

struct VS_INPUT_PTI
{
    float4 vPosition  : POSITION;
};

struct VS_OUTPUT_PTI
{
    float4  vPosition : POSITION;
};

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

VS_OUTPUT_PASS0_General VertexShader_Map_PASS0_General(const VS_INPUT v )
{
	VS_OUTPUT_PASS0_General Out = (VS_OUTPUT_PASS0_General)0;

	float4x4 WorldView = mul(WorldMatrix, ViewMatrix);
	float3 P = mul(v.vPosition, (float4x3)WorldView);
	Out.vPosition  = mul(float4(P, 1.0f), ProjectionMatrix);

	Out.vAlphaTexCoord		= v.vAlphaTexCoord;

	float4 WorldPosition = mul( v.vPosition, AbsoluteWorldMatrix );

	// OPTIMIZACIÓN: Se reemplaza la división (/ 8.0) por multiplicación (* 0.125)
	float2 TerrainCoord = (WorldPosition.xz + 0.5f) * 0.125f;

	Out.vTerrainTexCoord	= TerrainCoord;
	Out.vBaseTexCoord		= TerrainCoord;
	Out.vProvinceIndexCoord = v.vProvinceIndexCoord;

	return Out;
}

float4 PixelShader_Map_PASS0_General( VS_OUTPUT_PASS0_General v ) : COLOR
{
	float4 BaseColor = tex2D( BaseTexture, v.vBaseTexCoord );
	float4 Color = tex2D( GeneralTexture, v.vProvinceIndexCoord );
	return BaseColor * Color;
}

VS_OUTPUT_BEACH_PASS0_General VertexShader_Beach_PASS0_General(const VS_INPUT_BEACH v )
{
	VS_OUTPUT_BEACH_PASS0_General Out = (VS_OUTPUT_BEACH_PASS0_General)0;
	float4x4 WorldView = mul(WorldMatrix, ViewMatrix);
	float3 P = mul(v.vPosition, (float4x3)WorldView);
	Out.vPosition  = mul(float4(P, 1.0f), ProjectionMatrix);

	float3 VertexNormal = mul( v.vNormal, WorldMatrix );
	float3 direction = normalize( LightDirection );
	Out.vLightIntensityAndBeach.x = max( dot( VertexNormal, -direction ), 0.3f );
	Out.vLightIntensityAndBeach.y = v.vPosition.y * 2.0f;
	Out.vLightIntensityAndBeach.z = 0.0f;

	float4 WorldPosition	= mul( v.vPosition, AbsoluteWorldMatrix );

	// OPTIMIZACIÓN: Cambio de división por multiplicación flotante
	float2 TerrainCoord		= (WorldPosition.xz + 0.5f) * 0.125f;

	Out.vTexCoord0			= TerrainCoord;
	Out.vTexCoord1			= TerrainCoord;
	Out.vProvinceIndexCoord	= v.vProvinceIndexCoord;

	return Out;
}

float4 PixelShader_Beach_PASS0_General( VS_OUTPUT_BEACH_PASS0_General v ) : COLOR
{
	float4 BaseColor = tex2D( BaseTexture, v.vTexCoord0 );
	float4 TerrainColor = tex2D( MapTexture, v.vTexCoord1 );

	// OPTIMIZACIÓN: Reemplazo manual por una interpolación lineal más rápida
	float4 OutColor = lerp(BaseColor, TerrainColor, v.vLightIntensityAndBeach.y);

	float4 Color = tex2D( GeneralTexture, v.vProvinceIndexCoord.xy );
	OutColor *= v.vLightIntensityAndBeach.x;
	OutColor.rgb *= Color.rgb;
	OutColor.a = 1.0f;
	return OutColor;
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

VS_OUTPUT_PASS0 VertexShader_Map_PASS0(const VS_INPUT v )
{
	VS_OUTPUT_PASS0 Out = (VS_OUTPUT_PASS0)0;

	float4x4 WorldView = mul(WorldMatrix, ViewMatrix);
	float3 P = mul(v.vPosition, (float4x3)WorldView);
	Out.vPosition  = mul(float4(P, 1.0f), ProjectionMatrix);

	Out.vAlphaTexCoord		= v.vAlphaTexCoord;

	float4 WorldPosition = mul( v.vPosition, AbsoluteWorldMatrix );

	// OPTIMIZACIÓN: divisiones /2048 y /1024 convertidas a multiplicaciones exactas
	Out.vColorTexCoord.xy = float2( WorldPosition.x * 0.00048828125f, WorldPosition.z * 0.0009765625f );

	// OPTIMIZACIÓN: division /8 convertida a *0.125
	float2 TerrainCoord = (WorldPosition.xz + 0.5f) * 0.125f;
	Out.vTerrainTexCoord	= TerrainCoord;
	Out.vBaseTexCoord		= TerrainCoord;

	return Out;
}

VS_OUTPUT_PASS1 VertexShader_Map_PASS1(const VS_INPUT v )
{
	VS_OUTPUT_PASS1 Out = (VS_OUTPUT_PASS1)0;

	float4x4 WorldView = mul(WorldMatrix, ViewMatrix);
	float3 P = mul(v.vPosition, (float4x3)WorldView);
	Out.vPosition  = mul(float4(P, 1.0f), ProjectionMatrix);

	float3 VertexNormal = mul( v.vNormal, WorldMatrix );
	float3 direction = normalize( LightDirection );
	Out.vLightIntensity.xyz = max( dot( VertexNormal, -direction ), 0.3f );

	return Out;
}

float4 PixelShader_Map_PASS0( VS_OUTPUT_PASS0 v ) : COLOR
{
	float4 BaseColor = tex2D( BaseTexture, v.vBaseTexCoord );
	float4 TerrainColor = tex2D( MapTexture, v.vTerrainTexCoord );
	float TerrainAlpha = tex2D( TerrainAlphaTexture, v.vAlphaTexCoord ).a;
	float4 Color = tex2D( ColorTexture, v.vColorTexCoord );

	// OPTIMIZACIÓN: Se usa lerp nativo en lugar de la ecuación manual sumada
	float4 OutColor = lerp(BaseColor, TerrainColor, TerrainAlpha);
	OutColor.rgb *= Color.rgb;
	return OutColor;
}

float4 PixelShader_Map_PASS1( VS_OUTPUT_PASS1 v ) : COLOR
{
	return float4(v.vLightIntensity.xxx, 1.0f);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////

VS_OUTPUT_BEACH_PASS0 VertexShader_Beach_PASS0(const VS_INPUT_BEACH v )
{
	VS_OUTPUT_BEACH_PASS0 Out = (VS_OUTPUT_BEACH_PASS0)0;
	float4x4 WorldView = mul(WorldMatrix, ViewMatrix);
	float3 P = mul(v.vPosition, (float4x3)WorldView);
	Out.vPosition  = mul(float4(P, 1.0f), ProjectionMatrix);

	float3 VertexNormal = mul( v.vNormal, WorldMatrix );
	float3 direction = normalize( LightDirection );
	Out.vLightIntensityAndBeach.x = max( dot( VertexNormal, -direction ), 0.3f );
	Out.vLightIntensityAndBeach.y = v.vPosition.y * 2.0f;
	Out.vLightIntensityAndBeach.z = 0.0f;

	float4 WorldPosition = mul( v.vPosition, AbsoluteWorldMatrix );

	// OPTIMIZACIÓN: Multiplicaciones en lugar de divisiones pesadas
	Out.vColorTexCoord.xy = float2( WorldPosition.x * 0.00048828125f, WorldPosition.z * 0.0009765625f );
	float2 TerrainCoord = (WorldPosition.xz + 0.5f) * 0.125f;
	Out.vTexCoord0	= TerrainCoord;
	Out.vTexCoord1	= TerrainCoord;

	return Out;
}

float4 PixelShader_Beach_PASS0( VS_OUTPUT_BEACH_PASS0 v ) : COLOR
{
	float4 BaseColor = tex2D( BaseTexture, v.vTexCoord0 );
	float4 TerrainColor = tex2D( MapTexture, v.vTexCoord1 );

	// OPTIMIZACIÓN: Uso de lerp directo
	float4 OutColor = lerp(BaseColor, TerrainColor, v.vLightIntensityAndBeach.y);
	float4 Color = tex2D( ColorTexture, v.vColorTexCoord.xy );

	OutColor *= v.vLightIntensityAndBeach.x;
	OutColor.rgb *= Color.rgb;
	OutColor.a = 1.0f;
	return OutColor;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////

VS_OUTPUT_PTI VertexShader_PTI(const VS_INPUT_PTI v )
{
	VS_OUTPUT_PTI Out = (VS_OUTPUT_PTI)0;
	float4x4 WorldView = mul(WorldMatrix, ViewMatrix);
	float3 P = mul(v.vPosition, (float4x3)WorldView);
	Out.vPosition  = mul(float4(P, 1.0f), ProjectionMatrix);
	return Out;
}

float4 PixelShader_PTI( VS_OUTPUT_PTI v ) : COLOR
{
	return float4( 0.1f, 0.1f, 0.1f, 1.0f );
}
