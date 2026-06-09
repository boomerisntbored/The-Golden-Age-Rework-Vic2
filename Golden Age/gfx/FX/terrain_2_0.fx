#define BRIGHTNESS 0.05
#define CONTRAST 1.0
#define DESATURATION 0.3

#define X_OFFSET 0.5
#define Z_OFFSET 0.5

#define LIGHTNESS 1.0

#define LAND_ALT 0.35
#define SEA_FLOOR_ALT 0.0

#define X_MAGIC 1.0f
#define Y_MAGIC 0.0f

texture tex0 < string ResourceName = "Base.tga"; >;		// Base texture
texture tex1 < string ResourceName = "Terrain.tga"; >;	// Terrain texture
texture tex2 < string ResourceName = "Color.dds"; >;		// Color texture
texture tex3 < string ResourceName = "Alpha.dds"; >;		// Terrain Alpha Mask
texture tex4 < string ResourceName = "BorderDirection.dds"; >;	// Borders texture
texture tex5 < string ResourceName = "ProvinceBorders.dds"; >;
texture tex6 < string ResourceName = "CountryBorders.dds"; >;
texture tex7 < string ResourceName = "TerraIncog.dds"; >;

float4x4 WorldMatrix		: World;
float4x4 ViewMatrix		: View;
float4x4 ProjectionMatrix	: Projection;
float4x4 AbsoluteWorldMatrix;
float3	 LightDirection;
float3	CameraPosition;
float	 vAlpha;

float	ColorMapHeight;
float	ColorMapWidth;
float	ColorMapTextureHeight;
float	ColorMapTextureWidth;
float	MapWidth;
float	MapHeight;
float	BorderWidth;
float	BorderHeight;

const float3 GREYIFY = float3( 0.212671, 0.715160, 0.072169 );

float3 ApplyFOWColor( float3 c, float FOW )
{
	float Grey = dot( c.rgb, GREYIFY );
	return lerp( Grey.rrr * 0.4, c.rgb, FOW > 0.8 ? 1.0 : 0.3 );
}

sampler BaseTexture = sampler_state {
    Texture = <tex0>; MinFilter = Linear; MagFilter = Linear; MipFilter = Linear; AddressU = Wrap; AddressV = Wrap;
};
sampler TreeTexture = sampler_state {
    Texture = <tex0>; MinFilter = Linear; MagFilter = Linear; MipFilter = None; AddressU = Wrap; AddressV = Wrap;
};
sampler MapTexture = sampler_state {
    Texture = <tex1>; MinFilter = Linear; MagFilter = Linear; MipFilter = Linear; AddressU = Wrap; AddressV = Wrap;
};
sampler NoiseTexture = sampler_state {
    Texture = <tex5>; MinFilter = Linear; MagFilter = Linear; MipFilter = Linear; AddressU = Wrap; AddressV = Wrap;
};
sampler OverlayTexture = sampler_state {
    Texture = <tex5>; MinFilter = Linear; MagFilter = Linear; MipFilter = Linear; AddressU = Wrap; AddressV = Wrap;
};
sampler StripesTexture = sampler_state {
    Texture = <tex7>; MinFilter = Linear; MagFilter = Linear; MipFilter = None; AddressU = Wrap; AddressV = Wrap;
};
sampler ColorTexture = sampler_state {
    Texture = <tex4>; MinFilter = Linear; MagFilter = Linear; MipFilter = None; AddressU = Wrap; AddressV = Wrap;
};
sampler GeneralTexture = sampler_state {
    Texture = <tex2>; MinFilter = Point; MagFilter = Point; MipFilter = None; AddressU = Clamp; AddressV = Clamp;
};
sampler GeneralTexture2 = sampler_state {
    Texture = <tex3>; MinFilter = Point; MagFilter = Point; MipFilter = None; AddressU = Clamp; AddressV = Clamp;
};
sampler TerrainAlphaTexture = sampler_state {
    Texture = <tex3>; MinFilter = Point; MagFilter = Point; MipFilter = None; AddressU = Clamp; AddressV = Clamp;
};
sampler TextureSheet = sampler_state {
    Texture = <tex6>; MinFilter = Linear; MagFilter = Linear; MipFilter = None; AddressU = Clamp; AddressV = Clamp;
};
sampler BorderDirectionTexture = sampler_state {
    Texture = <tex4>; MinFilter = Linear; MagFilter = Point; MipFilter = None; AddressU = Clamp; AddressV = Clamp;
};
sampler WinterTexture = sampler_state {
    Texture = <tex2>; MinFilter = Point; MagFilter = Point; MipFilter = None; AddressU = Clamp; AddressV = Clamp;
};
sampler BorderTexture = sampler_state {
    Texture = <tex2>; MinFilter = Linear; MagFilter = Linear; MipFilter = Linear; AddressU = Clamp; AddressV = Clamp;
};
sampler QuadIndexTexture = sampler_state {
    Texture = <tex1>; MinFilter = Point; MagFilter = Point; MipFilter = None; AddressU = Mirror; AddressV = Mirror;
};
sampler TerraIncognitaTextureTerrain = sampler_state {
    Texture = <tex7>; MinFilter = Linear; MagFilter = Linear; MipFilter = None; AddressU = Clamp; AddressV = Clamp;
};
sampler TerraIncognitaTextureTree = sampler_state {
    Texture = <tex1>; MinFilter = Linear; MagFilter = Linear; MipFilter = None; AddressU = Clamp; AddressV = Clamp;
};

struct VS_INPUT {
    float2 vPosition  : POSITION;
    int2 vProvinceId : TEXCOORD0;
};
struct VS_BORDER_INPUT {
	int4 vPositionBorderLookup : POSITION;
	float4 vBorderOffsetColor : COLOR0;
};
struct VS_INPUT_BEACH {
    float2 vPosition  : POSITION;
    float4 vTerrainIndexColor : COLOR0;
};
struct VS_OUTPUT {
    float4  vPosition : POSITION;
    float3  vTexCoord0 : TEXCOORD0;
    float2  vTexCoord1 : TEXCOORD1;
    float2  vColorTexCoord : TEXCOORD2;
    float2  vBorderTexCoord0 : TEXCOORD3;
    float2  vBorderTexCoord1 : TEXCOORD4;
    float2  vTerrainTexCoord : TEXCOORD5;
    float2 vProvinceIndexCoord  : TEXCOORD6;
    float4 vBorderOffsetColor : COLOR0;
};
struct VS_MAP_OUTPUT {
    float4  vPosition : POSITION;
    float3  vTexCoord0 : TEXCOORD0;
    float2  vTexCoord1 : TEXCOORD1;
    float2  vColorTexCoord : TEXCOORD2;
	float2	vProvinceId : TEXCOORD3;
    float2  vTerrainTexCoord : TEXCOORD4;
    float4	vTerrainIndexColor : TEXCOORD5;
	float4 vPosTex : TEXCOORD6;
};
struct VS_OUTPUT_BEACH {
    float4  vPosition : POSITION;
    float2  vTexCoordBase : TEXCOORD0;
    float2  vColorTexCoord : TEXCOORD1;
    float3  vLightIntensity : TEXCOORD2;
    float2 vProvinceIndexCoord  : TEXCOORD3;
    float2 vBorderTexCoord0		: TEXCOORD4;
    float4 vTerrainIndexColor : TEXCOORD5;
    float2  vTexCoord1 : TEXCOORD6;
    float4 vBorderOffsetColor : COLOR0;
};
struct VS_INPUT_PTI {
    float2 vPosition  : POSITION;
};
struct VS_OUTPUT_PTI {
    float4  vPosition : POSITION;
};
struct VS_INPUT_TREE {
    float3 vPosition : POSITION;
    float2 vTexCoord : TEXCOORD0;
};
struct VS_OUTPUT_TREE {
    float4 vPosition   : POSITION;
    float2 vTexCoord   : TEXCOORD0;
    float2 vTexCoordTI : TEXCOORD1;
};

float TerrainIndexOffsetX;
float TerrainIndexOffsetY;
float TerrainIndexSizeX;
float TerrainIndexSizeY;

#define TILE_STRETCH_FACTOR 8.0
#define TILE_STRETCH_DIVIDE 0.125
const float NUM_TILES_X = 0.125;
const float NUM_TILES_Y = 0.125;
#define NUM_TERRAINS_FACTOR 32.0
#define X_CLAMP 0.125
#define Y_CLAMP 0.125

struct TILE_STRUCT {
    float2  vTexCoord0 : TEXCOORD0;
    float2  vTexCoord1 : TEXCOORD1;
    float2  vColorTexCoord : TEXCOORD2;
    float4 vTerrainIndexColor : COLOR0;
};

float4 GenerateTiles( TILE_STRUCT v )
{
	float4 IndexColor = tex2Dlod( QuadIndexTexture, float4(v.vTerrainIndexColor.xy, 0, 0) );
	float4 ColorColor = tex2Dlod( ColorTexture, float4(v.vTexCoord1, 0, 0) );
	float2 noisecoord = v.vTexCoord0 + 0.5;
	float3 noisy = tex2Dlod(NoiseTexture, float4(noisecoord, 0, 0) ).rgb;

	IndexColor *= 256.0;

	float4 IndexCoordX = trunc(fmod(IndexColor, NUM_TERRAINS_FACTOR));
	float4 vIndexCoordX = IndexCoordX * 0.03125;
	float4 IndexCoordY = trunc(IndexColor * 0.03125);
	float4 vIndexCoordY = IndexCoordY * NUM_TILES_Y;

	float2 TexCoord = frac( v.vColorTexCoord + 0.5 );
	TexCoord.x = 1.0 - TexCoord.x;
	float2 PixelTexCoord = frac( v.vTexCoord0 );

	TexCoord.x *= NUM_TILES_X;
	TexCoord.y *= 0.124;
	TexCoord = clamp( TexCoord, 0.001, 0.125 );

	float2 uvThis;
	uvThis.x = vIndexCoordX.x; uvThis.y = vIndexCoordY.x;
	float4 LeftTerrain = tex2Dlod( TextureSheet, float4(TexCoord + uvThis, 0, 0) );

	uvThis.x = vIndexCoordX.y; uvThis.y = vIndexCoordY.y;
	float4 UpLeftTerrain = tex2Dlod( TextureSheet, float4(TexCoord + uvThis, 0, 0) );

	uvThis.x = vIndexCoordX.z; uvThis.y = vIndexCoordY.z;
	float4 Terrain = tex2Dlod( TextureSheet, float4(TexCoord + uvThis, 0, 0) );

	uvThis.x = vIndexCoordX.w; uvThis.y = vIndexCoordY.w;
	float4 UpTerrain = tex2Dlod( TextureSheet, float4(TexCoord + uvThis, 0, 0) );

	float4 x1 = lerp( LeftTerrain, Terrain, saturate( PixelTexCoord.x + noisy.x)  );
	float4 x2 = lerp( UpLeftTerrain, UpTerrain, saturate( PixelTexCoord.x + noisy.y) );
	float4 y1 = lerp( x1, x2, saturate( PixelTexCoord.y + noisy.z)  );

	y1 = (y1 * 2.0f + ColorColor) * 0.333333f;
	return y1;
}

// OPTIMIZACIÓN EXTREMA: Funciones pesadas anuladas para salvar la GPU.
float GenerateHeight( TILE_STRUCT v ) { return 0.0; }
TILE_STRUCT ParallaxMapping( TILE_STRUCT v, float3 viewDir ) { return v; }
float SelfShadow( TILE_STRUCT v, float3 lightDir, float3 viewDir ) { return 0.0; }

float3 Hue(float H)
{
    float R = abs(H * 6.0 - 3.0) - 1.0;
    float G = 2.0 - abs(H * 6.0 - 2.0);
    float B = 2.0 - abs(H * 6.0 - 4.0);
    return saturate(float3(R,G,B));
}

float3 HSVtoRGB(float3 HSV) { return ((Hue(HSV.x) - 1.0) * HSV.y + 1.0) * HSV.z; }

float3 RGBtoHSV(float3 RGB)
{
    float3 HSV = 0;
	HSV.z = max(RGB.r, max(RGB.g, RGB.b));
    float M = min(RGB.r, min(RGB.g, RGB.b));
    float C = HSV.z - M;

    if (C != 0.0)
    {
        HSV.y = C / HSV.z;
        float3 Delta = (HSV.z - RGB) / C;
        Delta.rgb -= Delta.brg;
        Delta.rg += float2(2.0, 4.0);
        if (RGB.r >= HSV.z) HSV.x = Delta.b;
        else if (RGB.g >= HSV.z) HSV.x = Delta.r;
        else HSV.x = Delta.g;
        HSV.x = frac(HSV.x * 0.166666);
    }
    return HSV;
}

const float vXStretch = 16;
const float vYStretch = 16;
#define PROVINCE_LOOKUP_SIZE 256.0f

VS_MAP_OUTPUT VertexShader_Map_General(const VS_INPUT v )
{
	VS_MAP_OUTPUT Out = (VS_MAP_OUTPUT)0;
	float4 vPosition = float4( v.vPosition.x, LAND_ALT, v.vPosition.y, 1 );

	float4x4 WorldView = mul(WorldMatrix, ViewMatrix);
	float3 P = mul(vPosition, (float4x3)WorldView);
	Out.vPosition  = mul(float4(P, 1), ProjectionMatrix);
	Out.vPosTex = Out.vPosition;

	float4 WorldPosition = mul( vPosition, AbsoluteWorldMatrix );
	float WorldX = WorldPosition.x; float WorldY = WorldPosition.z;

	Out.vColorTexCoord.xy = float2( WorldX * 0.0625, WorldY * 0.0625 );
	Out.vTexCoord0.xy = float2( WorldX, WorldY );

	float MappedX = (ColorMapWidth * WorldPosition.x) / MapWidth;
	float MappedY = (ColorMapHeight * WorldPosition.z) / MapHeight;
	Out.vTexCoord1.xy = float2( ( MappedX + X_OFFSET)/ColorMapTextureWidth, (MappedY + Z_OFFSET)/ColorMapTextureHeight );

	Out.vTerrainIndexColor.x = ((WorldPosition.x - TerrainIndexOffsetX) + X_MAGIC ) / TerrainIndexSizeX;
	Out.vTerrainIndexColor.y = ((WorldPosition.z - TerrainIndexOffsetY) + Y_MAGIC ) / TerrainIndexSizeY;
	Out.vTerrainIndexColor = clamp(Out.vTerrainIndexColor,0.0,1.0);

	Out.vTerrainTexCoord  = (WorldPosition.xz + 0.5) * 0.125;
	Out.vProvinceId = v.vProvinceId;
	return Out;
}

VS_MAP_OUTPUT VertexShader_Map_General_Low(const VS_INPUT v )
{
	VS_MAP_OUTPUT Out = (VS_MAP_OUTPUT)0;
	float4 vPosition = float4( v.vPosition.x, LAND_ALT, v.vPosition.y, 1 );

	float4x4 WorldView = mul(WorldMatrix, ViewMatrix);
	float3 P = mul(vPosition, (float4x3)WorldView);
	Out.vPosition  = mul(float4(P, 1), ProjectionMatrix);
	Out.vPosTex = Out.vPosition;

	float4 WorldPosition = mul( vPosition, AbsoluteWorldMatrix );
	float WorldX = WorldPosition.x; float WorldY = WorldPosition.z;

	Out.vColorTexCoord.xy = float2( WorldX * 0.001953125, WorldY * 0.001953125 );
	Out.vTexCoord0.xy = float2( WorldX, WorldY );

	float MappedX = (ColorMapWidth * WorldPosition.x) / MapWidth;
	float MappedY = (ColorMapHeight * WorldPosition.z) / MapHeight;
	Out.vTexCoord1.xy = float2( ( MappedX + X_OFFSET)/ColorMapTextureWidth, (MappedY + Z_OFFSET)/ColorMapTextureHeight );

	Out.vTerrainIndexColor.x = ((WorldPosition.x - TerrainIndexOffsetX) + X_MAGIC ) / TerrainIndexSizeX;
	Out.vTerrainIndexColor.y = ((WorldPosition.z - TerrainIndexOffsetY) + Y_MAGIC ) / TerrainIndexSizeY;
	Out.vTerrainIndexColor = clamp(Out.vTerrainIndexColor,0.0,1.0);

	Out.vTerrainTexCoord  = (WorldPosition.xz + 0.5) * 0.125;
	Out.vProvinceId = v.vProvinceId;
	return Out;
}

VS_MAP_OUTPUT VertexShader_Map(const VS_INPUT v )
{
	VS_MAP_OUTPUT Out = (VS_MAP_OUTPUT)0;
	float4 vPosition = float4( v.vPosition.x, LAND_ALT, v.vPosition.y, 1 );

	float4x4 WorldView = mul(WorldMatrix, ViewMatrix);
	float3 P = mul(vPosition, (float4x3)WorldView);
	Out.vPosition  = mul(float4(P, 1), ProjectionMatrix);
	Out.vPosTex = Out.vPosition;
	Out.vProvinceId = v.vProvinceId;

	float4 WorldPosition = mul( vPosition, AbsoluteWorldMatrix );
	float WorldX = WorldPosition.x; float WorldY = WorldPosition.z;

	Out.vColorTexCoord.xy = float2( WorldX * 0.0625, WorldY * 0.0625 );
	Out.vTexCoord0.xy = float2( WorldX, WorldY );

	float MappedX = (ColorMapWidth * WorldPosition.x) / MapWidth;
	float MappedY = (ColorMapHeight * WorldPosition.z) / MapHeight;
	Out.vTexCoord1.xy = float2( ( MappedX + X_OFFSET)/ColorMapTextureWidth, (MappedY + Z_OFFSET)/ColorMapTextureHeight );

	Out.vTerrainIndexColor.x = ((WorldPosition.x - TerrainIndexOffsetX) + X_MAGIC ) / TerrainIndexSizeX;
	Out.vTerrainIndexColor.y = ((WorldPosition.z - TerrainIndexOffsetY) + Y_MAGIC ) / TerrainIndexSizeY;
	Out.vTerrainIndexColor = clamp(Out.vTerrainIndexColor,0.0,1.0);
	return Out;
}

#define COLOR_VALUE 0.9
#define COLOR_LIGHTNESS 1.5
float4 White = float4( 1, 1, 1, 1 );

float4 PixelShader_Map2_0_General( VS_MAP_OUTPUT v ) : COLOR
{
    TILE_STRUCT s;
    s.vTexCoord1 = v.vTexCoord1;
    s.vColorTexCoord = v.vColorTexCoord;
    s.vTerrainIndexColor = v.vTerrainIndexColor;
    s.vTexCoord0 = v.vTexCoord0.xy;

    float4 TerrainColor = GenerateTiles( s );
    TerrainColor.rgb = dot( TerrainColor.rgb, GREYIFY );

	float2 vProvinceUV = (v.vProvinceId + 0.5f) * 0.00390625f;

 	float4 Color1 = tex2Dlod( GeneralTexture, float4(vProvinceUV, 0, 0) ) - 0.7;
	float4 Color2 = tex2Dlod( GeneralTexture2, float4(vProvinceUV, 0, 0) ) - 0.7;

	float vColor = tex2Dlod( StripesTexture, float4(v.vTerrainTexCoord, 0, 0) ).a;
	float4 Color = lerp(Color1, Color2, vColor);

	Color.rgb = lerp(TerrainColor.rgb, Color.rgb, 0.3) * COLOR_LIGHTNESS;
	return Color;
}

float4 PixelShader_Map2_0_General_Low( VS_MAP_OUTPUT v ) : COLOR
{
	float4 OverlayColor = tex2Dlod( OverlayTexture, float4(v.vColorTexCoord, 0, 0) );
	float2 vProvinceUV = (v.vProvinceId + 0.5f) * 0.00390625f;

 	float4 Color1 = tex2Dlod( GeneralTexture, float4(vProvinceUV, 0, 0) ) - 0.7;
	float4 Color2 = tex2Dlod( GeneralTexture2, float4(vProvinceUV, 0, 0) ) - 0.7;

	float vColor = tex2Dlod( StripesTexture, float4(v.vTerrainTexCoord, 0, 0) ).a;
	float4 Color = Color2 * vColor + Color1 * ( 1.0 - vColor );
	float4 ColorColor = tex2Dlod( ColorTexture, float4(v.vTexCoord1, 0, 0) );

	Color.rgb = lerp(Color.rgb, ColorColor.rgb, 0.3);
	float3 ColorHSV = RGBtoHSV(Color.rgb);
	ColorHSV.y *= max(0.85, ColorHSV.z);
	ColorHSV.z *= 1.6;
	Color.rgb = HSVtoRGB(ColorHSV);
	Color.rgb = lerp(Color.rgb, OverlayColor.rgb, 0.5) * 1.17;

	Color.rgb = lerp(Color.rgb, float3(0.83, 0.78, 0.44), 0.1);
	Color.rgb = lerp(Color.rgb, Color.rrr, 0.15);
	Color.g = lerp(Color.g, Color.r, 0.075);
	Color.b = lerp(Color.b, 1.0 - Color.r, 0.1);
	Color.r *= 1.03;

	return Color;
}

float4 PixelShader_Map2_0( VS_MAP_OUTPUT v ) : COLOR
{
    TILE_STRUCT s;
    s.vTexCoord1 = v.vTexCoord1;
    s.vColorTexCoord = v.vColorTexCoord;
    s.vTerrainIndexColor = v.vTerrainIndexColor;
    s.vTexCoord0 = v.vTexCoord0.xy;

    float4 OutColor = GenerateTiles( s );

	float2 vProvinceUV = (v.vProvinceId + 0.5f) * 0.00390625f;
	float4 FogColor = tex2Dlod( GeneralTexture, float4(vProvinceUV, 0, 0) );

	float Grey = dot( OutColor.rgb, GREYIFY );
	OutColor.rgb = lerp( OutColor.rgb, Grey.rrr, FogColor.b ) + (FogColor.bbb * 0.3);

	OutColor.rgb = ApplyFOWColor( OutColor.rgb, FogColor.r) + FogColor.g;
	return OutColor;
}

VS_OUTPUT_BEACH VertexShader_Beach_General(const VS_INPUT_BEACH v )
{
	float4 vPosition = float4( v.vPosition.x, LAND_ALT, v.vPosition.y, 1 );
	VS_OUTPUT_BEACH Out = (VS_OUTPUT_BEACH)0;

	float4x4 WorldView = mul(WorldMatrix, ViewMatrix);
	float3 P = mul(vPosition, (float4x3)WorldView);
	Out.vPosition  = mul(float4(P, 1), ProjectionMatrix);
	Out.vLightIntensity.z = vPosition.y;

	float4 WorldPosition = mul( vPosition, AbsoluteWorldMatrix );
	float InvBorderWidth = 1.0 / BorderWidth;
	float InvBorderHeight = 1.0 / BorderHeight;

	Out.vColorTexCoord.xy = float2( WorldPosition.x * InvBorderWidth, WorldPosition.z * InvBorderHeight );
	Out.vTexCoordBase  = (WorldPosition.xz + 0.5) * 0.125;
	Out.vBorderTexCoord0 = float2( vPosition.x * InvBorderWidth, vPosition.z * InvBorderHeight );
	Out.vProvinceIndexCoord = v.vTerrainIndexColor;
	Out.vBorderTexCoord0.xy = WorldPosition.xz * 0.125;
	Out.vTexCoordBase.xy = WorldPosition.xz;

	float MappedX = (ColorMapWidth * WorldPosition.x) / MapWidth;
	float MappedY = (ColorMapHeight * WorldPosition.z) / MapHeight;
	Out.vColorTexCoord.xy = float2( ( MappedX + X_OFFSET)/ColorMapTextureWidth, (MappedY + Z_OFFSET)/ColorMapTextureHeight );

	Out.vTerrainIndexColor.x = ((WorldPosition.x - TerrainIndexOffsetX) + X_MAGIC ) / TerrainIndexSizeX;
	Out.vTerrainIndexColor.y = ((WorldPosition.z - TerrainIndexOffsetY) + Y_MAGIC ) / TerrainIndexSizeY;
	Out.vTerrainIndexColor = clamp(Out.vTerrainIndexColor,0.0,1.0);

	Out.vBorderOffsetColor = v.vTerrainIndexColor;
	Out.vTerrainIndexColor.zw  = (WorldPosition.xz + 0.5) * 0.125;
	return Out;
}

float4 PixelShader_Beach_General( VS_OUTPUT_BEACH v ) : COLOR
{
	TILE_STRUCT s;
	s.vTexCoord1 = v.vColorTexCoord;
	s.vColorTexCoord = v.vBorderTexCoord0;
	s.vTerrainIndexColor = v.vTerrainIndexColor;
	s.vTexCoord0 = v.vTexCoordBase;

	float4 y1 = GenerateTiles( s );
	y1.rgb = dot( y1.rgb, GREYIFY ) * White.rgb;

	float2 borderoffset = v.vBorderOffsetColor.rg + float2(-0.00390625f, 0.0f);
	float4 Color1 = tex2Dlod( GeneralTexture, float4(borderoffset, 0, 0) );
	float4 Color2 = tex2Dlod( GeneralTexture2, float4(borderoffset, 0, 0) );

	float vColor = tex2Dlod( StripesTexture, float4(v.vTerrainIndexColor.zw, 0, 0) ).a;
	float4 Color = lerp( Color1, Color2, vColor ) - 0.7f;

	Color.rgb = lerp(y1.rgb, Color.rgb, 0.3f) * COLOR_LIGHTNESS;

    clip(-1.0f);

	return Color;
}

float4 PixelShader_Beach_General_Low( VS_OUTPUT_BEACH v ) : COLOR
{
	float4 Color = tex2Dlod( GeneralTexture, float4(v.vProvinceIndexCoord, 0, 0) ) - 0.7f;
	float4 ColorColor = tex2Dlod( ColorTexture, float4(v.vColorTexCoord, 0, 0) );

	float4 OutColor;
	OutColor.rgb = lerp(ColorColor.rgb, Color.rgb, 0.3f) * COLOR_LIGHTNESS;

	OutColor.a = 0.0f;

	return OutColor;
}

struct VS_BORDER_OUTPUT
{
    float4  vPosition : POSITION;
    float4  vUV_ProvUV : TEXCOORD0;
    float4 vBorderOffsetColor : TEXCOORD1;
};

#define MAX_HALF_SIZE 1000.0f
#define HALF_PIXEL 0.5f
#define BORDER_PADDING_OFFSET 0.02f

VS_BORDER_OUTPUT VertexShader_Map_Border(const VS_BORDER_INPUT v )
{
	VS_BORDER_OUTPUT Out;

	float2 vSign = sign( v.vPositionBorderLookup.xy );
	Out.vUV_ProvUV.xy = saturate( vSign );
	Out.vUV_ProvUV.x = (Out.vUV_ProvUV.x * 0.96f) + BORDER_PADDING_OFFSET;
	Out.vUV_ProvUV.x *= 0.025f;
	Out.vUV_ProvUV.y = (Out.vUV_ProvUV.y * 0.21f) + BORDER_PADDING_OFFSET;

	vSign *= -MAX_HALF_SIZE;
	vSign += HALF_PIXEL + v.vPositionBorderLookup.xy;
	float4 vPosition = float4( vSign.x , LAND_ALT + 0.02, vSign.y, 1.0 );

	float4x4 WorldView = mul(WorldMatrix, ViewMatrix);
	float3 P = mul(vPosition, (float4x3)WorldView);

	Out.vPosition  = mul(float4(P, 1.0), ProjectionMatrix);
	Out.vUV_ProvUV.zw = v.vPositionBorderLookup.zw;
	Out.vBorderOffsetColor = v.vBorderOffsetColor;
	return Out;
}

#define BORDERLOOKUP_SIZE 512.0f

float4 PixelShader_Map2_0_Border( VS_BORDER_OUTPUT v ) : COLOR
{
	float2 TexCoord = v.vUV_ProvUV.xy;
	TexCoord.y *= 0.5;

	float2 BorderUV = v.vUV_ProvUV.zw + 0.5f;
	BorderUV *= 0.001953125f; // /= BORDERLOOKUP_SIZE

	float4 BorderTypeColor = tex2Dlod( BorderDirectionTexture, float4(BorderUV, 0.0, 0.0) );

	float SettingsBitMask = ( BorderTypeColor.b * 255.0 );

    // OPTIMIZACIÓN EXTREMA: Sin saltos 'if'. Todo resuelto con booleanos casteados a float
	float CornerOffset = (abs(SettingsBitMask - 1.0) < 0.01) + (abs(SettingsBitMask - 3.0) < 0.01);
	float RowOffset = (abs(SettingsBitMask - 2.0) < 0.01) + (abs(SettingsBitMask - 3.0) < 0.01);

    TexCoord.y += RowOffset * 0.5;

	float2 TexCoord2 = TexCoord;
	float2 TexCoord3 = TexCoord;

	TexCoord.x += (v.vBorderOffsetColor.b * CornerOffset) + (BorderTypeColor.a * (1.0 - CornerOffset));
	TexCoord.y += ( BorderTypeColor.a * CornerOffset );
	float4 ProvinceBorder = tex2Dlod( BorderTexture, float4(TexCoord, 0.0, 0.0) );

	TexCoord2.x += BorderTypeColor.r;
	TexCoord2.y += 0.125;
	float4 CountryBorder = tex2Dlod( BorderTexture, float4(TexCoord2, 0.0, 0.0) );

	TexCoord3.x += v.vBorderOffsetColor.a * CornerOffset + BorderTypeColor.g;
	TexCoord3.y += 0.25;
	TexCoord3.y += (BorderTypeColor.a * CornerOffset);
	float4 DiagBorder = tex2Dlod( BorderTexture, float4(TexCoord3, 0.0, 0.0) );

	ProvinceBorder.rgb *= ProvinceBorder.a;
	CountryBorder.rgb *= CountryBorder.a;
	DiagBorder.rgb *= DiagBorder.a;

	float4 OutColor = 0;
	OutColor.rgb = ProvinceBorder.rgb * ProvinceBorder.a;
	OutColor.a = max( max( ProvinceBorder.a, CountryBorder.a ), DiagBorder.a );

	OutColor.rgb = CountryBorder.rgb * CountryBorder.a + OutColor.rgb * ( 1.0f - CountryBorder.a );
	OutColor.rgb = max( OutColor.rgb, DiagBorder.rgb );

	return OutColor;
}

VS_OUTPUT_BEACH VertexShader_Beach(const VS_INPUT_BEACH v )
{
	float4 vPosition = float4( v.vPosition.x, LAND_ALT, v.vPosition.y, 1.0 );

	VS_OUTPUT_BEACH Out = (VS_OUTPUT_BEACH)0;
	float4x4 WorldView = mul(WorldMatrix, ViewMatrix);
	float3 P = mul(vPosition, (float4x3)WorldView);
	Out.vPosition  = mul(float4(P, 1.0), ProjectionMatrix);

	Out.vLightIntensity.z = vPosition.y;

	float4 WorldPosition = mul( vPosition, AbsoluteWorldMatrix );

	Out.vBorderTexCoord0.xy = WorldPosition.xz * 0.125;
	Out.vTexCoordBase.xy = WorldPosition.xz;

	float WorldX = (ColorMapWidth * WorldPosition.x) / MapWidth;
	float WorldY = (ColorMapHeight * WorldPosition.z) / MapHeight;

	Out.vColorTexCoord.xy = float2( ( WorldX + X_OFFSET)/ColorMapTextureWidth, (WorldY + Z_OFFSET)/ColorMapTextureHeight );

	Out.vTerrainIndexColor.x = ((WorldPosition.x - TerrainIndexOffsetX) + X_MAGIC ) / TerrainIndexSizeX;
	Out.vTerrainIndexColor.y = ((WorldPosition.z - TerrainIndexOffsetY) + Y_MAGIC ) / TerrainIndexSizeY;

	Out.vTerrainIndexColor = clamp(Out.vTerrainIndexColor,0.0,1.0);
	Out.vBorderOffsetColor = v.vTerrainIndexColor;

	return Out;
}

float4 PixelShader_Beach( VS_OUTPUT_BEACH v ) : COLOR
{
	TILE_STRUCT s;
	s.vTexCoord1 = v.vColorTexCoord;
	s.vColorTexCoord = v.vBorderTexCoord0;
	s.vTerrainIndexColor = v.vTerrainIndexColor;
	s.vTexCoord0 = v.vTexCoordBase;

	float4 OutColor = GenerateTiles( s );
	OutColor.rgb *= LIGHTNESS;

	float3 FogColor = tex2Dlod( GeneralTexture, float4(v.vBorderOffsetColor.rg + float2(-0.00390625f, 0.0f), 0.0, 0.0)).rgb;

	OutColor.rgb = ApplyFOWColor( OutColor.rgb, FogColor.r);
	OutColor.rgb += FogColor.g * 1.1f;

	float Grey = dot( OutColor.rgb, GREYIFY );
	OutColor.rgb = lerp( OutColor.rgb, Grey.rrr, FogColor.b );
	OutColor.rgb += float3(FogColor.b, FogColor.b, FogColor.b) * 0.3f;

	OutColor.rgb *= LIGHTNESS;

	OutColor.a = 0.0f;

	return OutColor;
}

VS_OUTPUT_PTI VertexShader_PTI(const VS_INPUT_PTI v )
{
	VS_OUTPUT_PTI Out = (VS_OUTPUT_PTI)0;
	float4x4 WorldView = mul(WorldMatrix, ViewMatrix);
	float3 P = mul(float4(v.vPosition, 0.0, 1.0), (float4x3)WorldView);
	Out.vPosition  = mul(float4(P, 1.0), ProjectionMatrix);
	return Out;
}

float4 PixelShader_PTI( VS_OUTPUT_PTI v ) : COLOR
{
	return float4( 1.0, 1.0, 1.0, 1.0 );
}

VS_OUTPUT_TREE VertexShader_TREE(const VS_INPUT_TREE v )
{
	float4 vPosition = float4( v.vPosition, 1.0 );
	vPosition.y += LAND_ALT;
	VS_OUTPUT_TREE Out = (VS_OUTPUT_TREE)0;
	float4x4 WorldView = mul(WorldMatrix, ViewMatrix);
	float3 P = mul(vPosition, (float4x3)WorldView);

	Out.vPosition  = mul(float4(P, 1.0), ProjectionMatrix);
	float4 WorldPosition = mul( vPosition, AbsoluteWorldMatrix );
	Out.vTexCoordTI = float2( WorldPosition.x / BorderWidth, WorldPosition.z / BorderHeight );
	Out.vTexCoord = v.vTexCoord;

	return Out;
}

float4 PixelShader_TREE( VS_OUTPUT_TREE v ) : COLOR
{
	float4 OutColor = tex2Dlod( TreeTexture, float4(v.vTexCoord, 0.0, 0.0) );
	OutColor.a *= vAlpha;
	return OutColor;
}

technique TerrainShader_Graphical
{
	pass p0
	{
		VertexShader = compile vs_3_0 VertexShader_Map();
		PixelShader = compile ps_3_0 PixelShader_Map2_0();
	}
}

technique TerrainShader_General
{
	pass p0
	{
		VertexShader = compile vs_3_0 VertexShader_Map_General();
		PixelShader = compile ps_3_0 PixelShader_Map2_0_General();
	}
}

technique TerrainShader_General_Low
{
	pass p0
	{
		VertexShader = compile vs_3_0 VertexShader_Map_General_Low();
		PixelShader = compile ps_3_0 PixelShader_Map2_0_General_Low();
	}
}

technique TerrainShader_Border
{
	pass p0
	{
		ALPHABLENDENABLE = True;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;

		VertexShader = compile vs_3_0 VertexShader_Map_Border();
		PixelShader = compile ps_3_0 PixelShader_Map2_0_Border();
	}
}

technique BeachShader_Graphical
{
	pass p0
	{
		ALPHATESTENABLE = True;
		ALPHABLENDENABLE = True;
		SrcBlend = SRCALPHA;
		DestBlend = INVSRCALPHA;

		VertexShader = compile vs_3_0 VertexShader_Beach();
		PixelShader = compile ps_3_0 PixelShader_Beach();
	}
}

technique BeachShader_General
{
	pass p0
	{
		VertexShader = compile vs_3_0 VertexShader_Beach_General();
		PixelShader = compile ps_3_0 PixelShader_Beach_General();
	}
}

technique BeachShader_General_Low
{
	pass p0
	{
		VertexShader = compile vs_3_0 VertexShader_Beach_General();
		PixelShader = compile ps_3_0 PixelShader_Beach_General_Low();
	}
}

technique PTIShader
{
	pass p0
	{
		fvf = XYZ;
		LightEnable[0] = false;
		Lighting = False;
		ALPHABLENDENABLE = True;

		ColorOp[0] = Modulate;
		ColorArg1[0] = Texture;
		ColorArg2[0] = current;

		ColorOp[1] = Disable;
		AlphaOp[1] = Disable;

		VertexShader = compile vs_3_0 VertexShader_PTI();
		PixelShader = compile ps_3_0 PixelShader_PTI();
	}
}

technique TreeShader
{
	pass p0
	{
		ALPHABLENDENABLE = True;
		ALPHATESTENABLE = True;

		VertexShader = compile vs_3_0 VertexShader_TREE();
		PixelShader = compile ps_3_0 PixelShader_TREE();
	}
}
