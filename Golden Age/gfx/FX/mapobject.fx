texture tex0 : Diffuse < string ResourceName = "Diffuse.tga"; >;
texture tex1 : Diffuse < string ResourceName = "FOW.tga"; >;

float4x4 WorldMatrix			: World;
float4x4 ViewMatrix;
float4x4 ProjectionMatrix;
float4x4 WorldViewProjectionMatrix;
float4x4 AbsoluteWorldMatrix;

float4 LightDirection;
float4 LightAmbient;
float4 LightColor;

sampler2D DiffuseTexture =
sampler_state
{
    texture = <tex0>;
    AddressU  = Clamp;
    AddressV  = Clamp;
    AddressW  = Clamp;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;
};

sampler2D TerraIncognitaTexture =
sampler_state
{
    texture = <tex1>;
    MipFilter = None;
    MinFilter = Linear;
    MagFilter = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
};

struct VS_INPUT
{
   float4 Position : POSITION;
   float2 TexCoord : TEXCOORD0;
   float3 Normal   : NORMAL;
};

struct VS_OUTPUT
{
   float4 Position :        POSITION;
   float2 TexCoord :        TEXCOORD0;
   float3 LightDirection :  TEXCOORD1;
   float2 WorldCoord :      TEXCOORD2;
   float3 Normal :          TEXCOORD3;
   float3 Diffuse  :	    COLOR;
};

VS_OUTPUT MapObject_VS( VS_INPUT In )
{
	VS_OUTPUT Out = (VS_OUTPUT)0;

	Out.Position = mul( float4(In.Position.xyz, 1.0f), WorldViewProjectionMatrix );
	Out.Normal = mul( In.Normal, (float3x3)WorldMatrix );
	Out.LightDirection = LightDirection.xyz;
	Out.TexCoord = In.TexCoord;

	float4 WorldPosition = mul( In.Position, AbsoluteWorldMatrix );

	// OPTIMIZACIÓN: Se eliminan las divisiones pesadas aplicando multiplicación por el recíproco exacto en un float2 vectorizado
	Out.WorldCoord = WorldPosition.xz * float2(0.00048828125f, 0.0009765625f);

	return Out;
}

float4 MapObject_PS( VS_OUTPUT In ) : COLOR
{
	float3 Normal = normalize(In.Normal);

	// Calculamos el factor difuso como un escalar puro
	float diff = dot( Normal, -In.LightDirection );

	// OPTIMIZACIÓN: Factorización algebraica del modelo de iluminación y el lerp intermedio.
	// Reducimos drásticamente las instrucciones vectoriales complejas sobre el muestreo de textura.
	float3 lightingFactor = 0.5f * (LightAmbient.rgb + diff * LightColor.rgb) + 0.5f;

	float4 Diffuse = tex2D( DiffuseTexture, In.TexCoord );
	float3 ColorOut = Diffuse.rgb * lightingFactor;

	// Terra incognita
	float4 TerraIncognita = tex2D( TerraIncognitaTexture, In.WorldCoord );
	ColorOut.rgb += ( TerraIncognita.g - 0.25f ) * 1.33f;

	return float4( ColorOut, 1.0f );
}

technique MapObjectShader
{
	pass p0
	{
		VertexShader = compile vs_1_1 MapObject_VS();
		PixelShader = compile ps_2_0 MapObject_PS();
	}
}
