texture tex0 < string name = "Beach.tga"; >;
texture tex1 < string name = "Beach.tga"; >;
texture tex2 < string name = "Beach.tga"; >;
texture tex3 < string name = "Beach.tga"; >;

float4x4 WorldMatrix;
float4x4 ViewMatrix;
float4x4 ProjectionMatrix;
float	 vWaterHeight;
float	 vTime;
float	 vCameraHeight;
float4x4 AbsoluteWorldMatrix;

sampler BaseTexture  =
sampler_state
{
    Texture = <tex0>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler AlphaTexture  =
sampler_state
{
    Texture = <tex1>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler AlphaGradientTexture  =
sampler_state
{
    Texture = <tex2>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler SandTexture  =
sampler_state
{
    Texture = <tex2>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler TerraIncognitaFiltered  =
sampler_state
{
    Texture = <tex3>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
    AddressU = Clamp;
    AddressV = Clamp;
};

struct VS_INPUT
{
    int4 vPositionUV	: POSITION;
};

struct VS_OUTPUT
{
    float4  vPosition  : POSITION;
    float2  vTexCoord0 : TEXCOORD0;
    float2  vTexCoord1 : TEXCOORD1;
};

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

VS_OUTPUT VertexShader_Beach(const VS_INPUT v )
{
	VS_OUTPUT Out = (VS_OUTPUT)0;
	float4x4 WorldView = mul(WorldMatrix, ViewMatrix);

	// Se formatea la posición usando literales flotantes limpios
	float4 Position = float4( v.vPositionUV.x * 0.5f, vWaterHeight, v.vPositionUV.y * 0.5f, 1.0f );
	float3 P = mul( Position, (float4x3)WorldView);
	Out.vPosition  = mul(float4(P, 1.0f), ProjectionMatrix);

	// Multiplicaciones limpias para las coordenadas de textura
	float2 UVBase = v.vPositionUV.zw * 0.01f;
	Out.vTexCoord1 = UVBase;
	Out.vTexCoord0 = UVBase - float2( 0.0f, vTime * 0.2f );

	return Out;
}

float4 PixelShader_Beach( VS_OUTPUT v ) : COLOR
{
	float4 OutColor = tex2D( BaseTexture, v.vTexCoord0.xy );
	float4 AlphaColor = tex2D( AlphaTexture, v.vTexCoord1.xy );

	// OPTIMIZACIÓN: Se eliminó una línea muerta redundante (v.vTexCoord1.y = v.vTexCoord1.y)
	float4 GradientColor = tex2D( AlphaGradientTexture, v.vTexCoord1.xy );

	// Encadenamiento de operaciones de opacidad directo
	OutColor *= AlphaColor.a * GradientColor.a;

	return OutColor;
}

float4 PixelShader_Beach_Color( VS_OUTPUT v ) : COLOR
{
	float4 OutColor = float4( 0.0f, 0.0f, 0.0f, 1.0f );
	float4 AlphaColor = tex2D( AlphaTexture, v.vTexCoord1.xy );

	// OPTIMIZACIÓN EXTREMA:
	// La ecuación original: 1 - (vCameraHeight - 600) / 500
	// Sustituida algebraicamente dentro de 'saturate' se reduce a una única instrucción MAD por hardware:
	// AlphaColor.a * 2.0f + vCameraHeight * 0.001f - 1.6f

	OutColor.a = saturate( AlphaColor.a * 2.0f + vCameraHeight * 0.001f - 1.6f ) * 0.7f;

	return OutColor;
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

technique BeachShader
{
	pass p0
	{
		ALPHABLENDENABLE = True;
		ALPHATESTENABLE = True;

		SrcBlend = SRCALPHA;
		DestBlend = ONE;

		VertexShader = compile vs_1_1 VertexShader_Beach();
		PixelShader = compile ps_2_0 PixelShader_Beach();
	}
}

technique BeachShaderColor
{
	pass p0
	{
		ALPHABLENDENABLE = True;
		ALPHATESTENABLE = True;

		VertexShader = compile vs_1_1 VertexShader_Beach();
		PixelShader = compile ps_2_0 PixelShader_Beach_Color();
	}
}
