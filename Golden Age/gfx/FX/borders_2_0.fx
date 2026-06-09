texture tex0 < string ResourceName = "borders.tga"; >;
texture tex1 < string ResourceName = "borderDirections.tga"; >;
texture tex2 < string ResourceName = "TerraIncog.tga"; >;
texture tex3 < string ResourceName = "Diag.tga"; >;
texture tex4 < string ResourceName = "ColorWater.tga"; >;

float4x4 WorldMatrix		: World;
float4x4 ViewMatrix		: View;
float4x4 ProjectionMatrix	: Projection;

#define EXTRA_U 0.0075f
#define X_OFFSET 0.5
#define Z_OFFSET 0.5

float	ColorMapHeight;
float	ColorMapWidth;
float	ColorMapTextureHeight;
float	ColorMapTextureWidth;
float	MapWidth;
float	MapHeight;
float	BorderTextureWidth;
float	BorderTextureHeight;

sampler BaseTexture  =
sampler_state
{
    Texture = <tex0>;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None; // CORREGIDO: Ya no causa crash de sintaxis
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler ProvinceBorderTexture  =
sampler_state
{
    Texture = <tex1>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler TerraIncognitaFiltered  =
sampler_state
{
    Texture = <tex2>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler ProvinceBorderDiagTexture  =
sampler_state
{
    Texture = <tex3>;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    AddressU = Clamp;
    AddressV = Clamp;
};

sampler ColorWaterTexture  =
sampler_state
{
    Texture = <tex4>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
    AddressU = Clamp;
    AddressV = Clamp;
};

struct VS_INPUT
{
    float4 vPosition  : POSITION;
    float2 vTexCoord  : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4  vPosition : POSITION;
    float2  vTexCoord0 : TEXCOORD0;
    float2  vTexCoord1 : TEXCOORD1;
	float2	vColorTex  : TEXCOORD2;
};

struct VS_WATERINPUT
{
    float4 vPosition  : POSITION;
    float2 vProvCoord  : TEXCOORD0;
    float2 vDiagCoord  : TEXCOORD1;
};

struct VS_WATEROUTPUT
{
    float4 vPosition  : POSITION;
    float2 vProvCoord  : TEXCOORD0;
    float2 vDiagCoord  : TEXCOORD1;
};

/////////////////////////////////////////////////////////////////////////////////

#define WATER_BORDER_ALT 0.0
float4x4 WorldViewProjectionMatrix;

VS_WATEROUTPUT VertexShader_WaterBorder(const VS_WATERINPUT v )
{
	VS_WATEROUTPUT Out = (VS_WATEROUTPUT)0;
	float3 P = float3( v.vPosition.x, WATER_BORDER_ALT, v.vPosition.y );
	P.z -= 0.7f;

	Out.vPosition = mul( float4(P, 1.0f), WorldViewProjectionMatrix );
	Out.vPosition.y += 2.0f;
	Out.vProvCoord  = v.vProvCoord;
	Out.vDiagCoord  = v.vDiagCoord;

	return Out;
}

float4 PixelShader_WaterBorder( VS_WATEROUTPUT v ) : COLOR
{
	float4 Color = tex2D( ProvinceBorderTexture, v.vProvCoord );
	Color.rgb *= Color.a;

	float4 DiagColor = tex2D( ProvinceBorderDiagTexture, v.vDiagCoord );
	DiagColor.rgb *= DiagColor.a;

	Color.rgb = max( DiagColor.rgb, Color.rgb );
	Color.a = max( Color.a, DiagColor.a );
	return Color;
}

VS_OUTPUT VertexShader_Border(const VS_INPUT v )
{
	VS_OUTPUT Out = (VS_OUTPUT)0;

	float4x4 WorldView = mul(WorldMatrix, ViewMatrix);
	float3 P = mul(v.vPosition, (float4x3)WorldView);
	Out.vPosition  = mul(float4(P, 1.0f), ProjectionMatrix);

	Out.vTexCoord0  = v.vTexCoord;
	Out.vTexCoord0.y += EXTRA_U;

	Out.vColorTex.x = Out.vTexCoord0.x * (ColorMapWidth / MapWidth);
	Out.vColorTex.y = Out.vTexCoord0.y * (ColorMapHeight / MapHeight);

	float2 TexCoord = v.vTexCoord + float2(0.0f, 0.0293f);
	TexCoord.x *= BorderTextureWidth;
	TexCoord.y *= BorderTextureHeight;

	Out.vTexCoord1 = TexCoord;

	return Out;
}

float4 PixelShader_ProvinceBorder( VS_OUTPUT v ) : COLOR
{
	float4 BaseColor = tex2D( BaseTexture, v.vTexCoord0 );

	float2 TexCoord = frac(v.vTexCoord1);

	TexCoord.y = ( 1.0f - TexCoord.y );
	TexCoord.x *= 0.05f;

	float2 TexCoord2 = TexCoord;
	TexCoord.x += BaseColor.b;
	TexCoord2.x += BaseColor.a;

	float4 Color = tex2D( ProvinceBorderTexture, TexCoord );
	Color.rgb *= Color.a;

	float4 DiagColor = tex2D( ProvinceBorderDiagTexture, TexCoord2 );
	DiagColor.rgb *= DiagColor.a;

	Color.rgb = max( DiagColor.rgb, Color.rgb );
	Color.a = max( Color.a, DiagColor.a );

	float4 TerraIncognita = tex2D( TerraIncognitaFiltered, v.vTexCoord0 );
	Color.rgb += ( TerraIncognita.g - 0.25f ) * 1.33f;

	Color.rgb += tex2D( ColorWaterTexture, v.vColorTex ).aaa;

	return Color;
}

float4 PixelShader_CountryBorder( VS_OUTPUT v ) : COLOR
{
	float4 BaseColor = tex2D( BaseTexture, v.vTexCoord0 );

	float2 TexCoord = frac(v.vTexCoord1);

	TexCoord.x *= 0.05859375f;
	TexCoord.x += ( BaseColor.r * 0.97f );

	return tex2D( ProvinceBorderTexture, TexCoord );
}

float4 PixelShader_River( VS_OUTPUT v ) : COLOR
{
	float4 BaseColor = tex2D( BaseTexture, v.vTexCoord0 );

	float2 TexCoord = frac(v.vTexCoord1);

	TexCoord.x *= 0.05859375f;
	TexCoord.x += ( BaseColor.g * 0.99f );

	return tex2D( ProvinceBorderTexture, TexCoord );
}

/////////////////////////////////////////////////////////////////////////////////

technique ProvinceBorderShader
{
	pass p0
	{
		ALPHABLENDENABLE = True;
		VertexShader = compile vs_1_1 VertexShader_Border();
		PixelShader = compile ps_2_0 PixelShader_ProvinceBorder();
	}
}

technique CountryBorderShader
{
	pass p0
	{
		ALPHABLENDENABLE = True;
		VertexShader = compile vs_1_1 VertexShader_Border();
		PixelShader = compile ps_2_0 PixelShader_CountryBorder();
	}
}

technique RiverShader
{
	pass p0
	{
		ALPHABLENDENABLE = True;
		VertexShader = compile vs_1_1 VertexShader_Border();
		PixelShader = compile ps_2_0 PixelShader_River();
	}
}

technique WaterBorderShader
{
	pass p0
	{
		ALPHABLENDENABLE = True;
		VertexShader = compile vs_1_1 VertexShader_WaterBorder();
		PixelShader = compile ps_2_0 PixelShader_WaterBorder();
	}
}
