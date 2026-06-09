float4x4 ViewProjectionMatrix;
float4x4 WorldMatrix;
float3 CameraPosition;
float4x4 matBones[45] : Bones;
float3 LightDirection;
float Time;
float4 TextureOffset;
float4 PrimaryColor   = float4(0.8, 0.0, 0, 1);
float4 SecondaryColor = float4(0.0, 0.7, 0, 1);

float FOW = 1.0;

// select lighting model to use
#define LIGHTMODEL_WRAP
#define DEBUG_SHOW_NORMALMAP

const int SKINNING_INFLUENCES = 2;

float SPECULAR_POWER = 20;
float SPECULARITY = 1.25;
const float WRAP = 0.7;
const float AMBIENT = 0.0;
const float INTENSITY = 1.75;
const float3 LIGHT_OFFSET = float3(-250, -500, 200);

const float TRACK_SPEED = 2.5;

// Flag specific
const float ANIMATION_SPEED = 0.3;
const float INTENSITY_FLAG = 0.9;
const float3 LIGHT_OFFSET_FLAG = float3(-250, -500, 100);
const float FLAG_GRAYNESS = 0.3;
float SPECULAR_POWER_FLAG = 10;
float SPECULARITY_FLAG = 0.1;

texture tex0 : DiffuseTexture;
sampler2D DiffuseMap =
sampler_state
{
    texture = <tex0>;
    AddressU  = Wrap;
    AddressV  = Wrap;
    MipFilter = Linear;
    MagFilter = Linear;
	MinFilter = Anisotropic;
    MaxAnisotropy = 4;
};

texture tex1 : Texture1;
sampler2D SpecularMap =
sampler_state
{
    texture = <tex1>;
    AddressU  = Wrap;
    AddressV  = Wrap;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;
};

sampler2D NormalMap =
sampler_state
{
    texture = <tex1>;
    AddressU  = Wrap;
    AddressV  = Wrap;
    MipFilter = Linear;
    MagFilter = Linear;
	MinFilter = Linear;
};

struct VS_INPUT
{
    float4 vPosition   : POSITION;
    float3 vNormal     : NORMAL;
	float4 vTangent    : TANGENT;
	float2 vTexCoord0  : TEXCOORD0;
	float4 boneIndices : BLENDINDICES;
    float4 boneWeights : BLENDWEIGHT;
};

struct VS_OUTPUT
{
    float4 vPosition  : POSITION;
	float2 vTexCoord0 : TEXCOORD0;
	float3 Normal     : TEXCOORD1;
	float3 LightDirection : TEXCOORD2;
	float3 EyeVec : TEXCOORD3;
};

float3 ApplyFOWColor( float3 c )
{
	const float3 GREYIFY = float3( 0.212671, 0.715160, 0.072169 );
	float Grey = dot( c.rgb, GREYIFY );
	return lerp( Grey.rrr * 0.4f, c.rgb, FOW > 0.5f ? 1.0f : 0.5f );
}

VS_OUTPUT SkinnedAvatarVS(const VS_INPUT v )
{
	VS_OUTPUT Out = (VS_OUTPUT)0;
	float4 vPosition = float4(v.vPosition.xyz, 1.0f);
	float3 normNormal = normalize(v.vNormal);

	// OPTIMIZACIÓN: Loop Unrolling manual para eliminar la sobrecarga de saltos condicionales de vértices
	// Hueso 1
	float4x4 mat0 = matBones[ (int)v.boneIndices[0] ];
	float4 skinnedPosition = mul( vPosition, mat0 ) * v.boneWeights[0];
	float4 skinnedNormal   = mul( float4(normNormal, 0.0f), mat0 ) * v.boneWeights[0];

	// Hueso 2
	float4x4 mat1 = matBones[ (int)v.boneIndices[1] ];
	skinnedPosition += mul( vPosition, mat1 ) * v.boneWeights[1];
	skinnedNormal   += mul( float4(normNormal, 0.0f), mat1 ) * v.boneWeights[1];

	Out.LightDirection = -normalize(skinnedPosition.xyz - CameraPosition + LIGHT_OFFSET );
	Out.EyeVec = -normalize(skinnedPosition.xyz - CameraPosition);

	Out.vPosition = mul(skinnedPosition, ViewProjectionMatrix );
	Out.vTexCoord0 = v.vTexCoord0;
	Out.Normal  = normalize(skinnedNormal.xyz);

	return Out;
}

float4 SkinnedAvatarPS( VS_OUTPUT In ) : COLOR
{
	float4 vColor = tex2D( DiffuseMap, In.vTexCoord0 );
	float3 vSpecColor = tex2D( SpecularMap, In.vTexCoord0 ).rgb;
	float3 vNormal = normalize(In.Normal);

	vColor.rgb = lerp(vColor.rgb, vColor.rgb * (PrimaryColor.rgb * vSpecColor.g), vSpecColor.g);
	vColor.rgb = lerp(vColor.rgb, vColor.rgb * (SecondaryColor.rgb * vSpecColor.b), vSpecColor.b);

	float3 L = normalize(In.LightDirection);
	float3 E = normalize(In.EyeVec);
	float3 halfVec = normalize(E + L);
	float  NdotL = max(0.0f, dot(vNormal, L));

	#ifdef LIGHTMODEL_WRAP
	// OPTIMIZACIÓN: División por 1.7 reemplazada por multiplicación exacta por recíproco (* 0.5882353f)
	float diffuse = saturate((NdotL + 0.7f) * 0.5882353f) * INTENSITY;
	#endif
	#ifdef LIGHTMODEL_HALFLAMBERT
	float diffuse = pow(0.5f * NdotL + 0.5f, 2.0f) * INTENSITY;
	#endif
	#ifdef LIGHTMODEL_PHONG
	float diffuse = NdotL * INTENSITY + AMBIENT;
	#endif

    float NDotH = dot(vNormal, halfVec);
	float specular = pow( saturate(NDotH), SPECULAR_POWER );
	specular *= vSpecColor.r * SPECULARITY;

	return float4( ApplyFOWColor(vColor.rgb * diffuse + specular), 1.0f );
}

float2 GetTexCoordsInAtlas(float2 TexCoord)
{
	// OPTIMIZACIÓN: Vectorización completa eliminando la separación de componentes escalares .x / .y
	return (TexCoord / TextureOffset.xy) + TextureOffset.zw;
}

VS_OUTPUT SkinnedAvatarVSFlag(const VS_INPUT v )
{
	VS_OUTPUT Out = (VS_OUTPUT)0;
	float4 vPosition = float4(v.vPosition.xyz, 1.0f);
	float3 normNormal = normalize(v.vNormal);
	float3 normTangent = normalize(v.vTangent.xyz);

	// OPTIMIZACIÓN: Loop Unrolling manual en banderas
	// Hueso 1
	float4x4 mat0 = matBones[ (int)v.boneIndices[0] ];
	float4 skinnedPosition = mul( vPosition, mat0 ) * v.boneWeights[0];
	float4 skinnedNormal   = mul( float4(normNormal, 0.0f), mat0 ) * v.boneWeights[0];
	float4 skinnedTangent  = mul( float4(normTangent, 0.0f), mat0 ) * v.boneWeights[0];

	// Hueso 2
	float4x4 mat1 = matBones[ (int)v.boneIndices[1] ];
	skinnedPosition += mul( vPosition, mat1 ) * v.boneWeights[1];
	skinnedNormal   += mul( float4(normNormal, 0.0f), mat1 ) * v.boneWeights[1];
	skinnedTangent  += mul( float4(normTangent, 0.0f), mat1 ) * v.boneWeights[1];

	float3 sNormal  = normalize(skinnedNormal.xyz);
	float3 sTangent = normalize(skinnedTangent.xyz);

	// OPTIMIZACIÓN: Se removió la llamada inútil 'normalize(binormal)' que no guardaba datos
	float3 binormal = normalize(cross(sTangent, sNormal) * v.vTangent.w);

	float3x3 matTBN = float3x3(sTangent, binormal, sNormal);
	Out.LightDirection = mul(matTBN, -normalize(skinnedPosition.xyz - CameraPosition + LIGHT_OFFSET_FLAG ));
	Out.EyeVec = mul(matTBN, -normalize(skinnedPosition.xyz - CameraPosition));

	Out.vPosition = mul(skinnedPosition, ViewProjectionMatrix );
	Out.vTexCoord0 = v.vTexCoord0;

	return Out;
}

float4 SkinnedAvatarPSFlag( VS_OUTPUT In ) : COLOR
{
	float t = frac(Time * ANIMATION_SPEED);
	float2 NormalCoord = float2(In.vTexCoord0.x - t, In.vTexCoord0.y );

	float4 vColor = tex2D( DiffuseMap, GetTexCoordsInAtlas(In.vTexCoord0) );
	float3 vNormal = normalize( tex2D( NormalMap, NormalCoord ).rgb * 2.0f - 1.0f );

	float3 L = normalize(In.LightDirection);
	float3 E = normalize(In.EyeVec);
	float3 halfVec = normalize(E + L);
	float  NdotL = dot(vNormal, L);

	#ifdef LIGHTMODEL_WRAP
	float diffuse = saturate((saturate(NdotL) + 0.7f) * 0.5882353f) * INTENSITY_FLAG;
	#endif
	#ifdef LIGHTMODEL_HALFLAMBERT
	float diffuse = pow(0.5f * saturate(NdotL) + 0.5f, 2.0f) * INTENSITY_FLAG;
	#endif
	#ifdef LIGHTMODEL_PHONG
	float diffuse = saturate(NdotL) * INTENSITY_FLAG + AMBIENT;
	#endif

	float specular = pow( saturate( dot(vNormal, halfVec) ), SPECULAR_POWER_FLAG );

	// OPTIMIZACIÓN: Eliminación de la bifurcación lógica 'if (NdotL <= 0)' mediante multiplicación branchless por paso de hardware
	specular *= (SPECULARITY_FLAG * step(0.0f, NdotL));

	vColor.rgb = vColor.rgb * saturate(diffuse);
	float Grey = dot( vColor.rgb, float3( 0.212671f, 0.715160f, 0.072169f ) );
	return float4(lerp( vColor.rgb, Grey.rrr, FLAG_GRAYNESS ) + specular, vColor.a);
}

float4 SkinnedAvatarPSShadow( VS_OUTPUT In ) : COLOR
{
	return tex2D( DiffuseMap, In.vTexCoord0 );
}

float4 SkinnedAvatarPSSmoke( VS_OUTPUT In ) : COLOR
{
	float t = frac(Time * ANIMATION_SPEED);
	float vAlphaLocal = tex2D( DiffuseMap, In.vTexCoord0 ).a;
	float4 vColor = tex2D( DiffuseMap, float2(In.vTexCoord0.x, In.vTexCoord0.y + t) );
	vColor.a = vAlphaLocal;
	return vColor;
}

float4 SkinnedAvatarPSTracks( VS_OUTPUT In ) : COLOR
{
	float t = frac(Time * TRACK_SPEED);
	return tex2D( DiffuseMap, float2(In.vTexCoord0.x, In.vTexCoord0.y + t) );
}

/////////////////////////////////////////////////////

technique Standard
{
	pass p0
	{
		MipMapLodBias[0] = -1.0;
		VertexShader = compile vs_2_0 SkinnedAvatarVS();
		PixelShader = compile ps_2_0 SkinnedAvatarPS();
	}
}

technique Flag
{
	pass p0
	{
		VertexShader = compile vs_2_0 SkinnedAvatarVSFlag();
		PixelShader = compile ps_2_0 SkinnedAvatarPSFlag();
	}
}

technique Shadow
{
	pass p0
	{
		ZENABLE = True;
		ALPHABLENDENABLE = True;
		ALPHATESTENABLE = False;
		ZWRITEENABLE = False;
		VertexShader = compile vs_2_0 SkinnedAvatarVS();
		PixelShader = compile ps_2_0 SkinnedAvatarPSShadow();
	}
}

technique Smoke
{
	pass p0
	{
		ZENABLE = True;
		ZWRITEENABLE = False;
		ALPHABLENDENABLE = True;
		ALPHATESTENABLE = False;
		VertexShader = compile vs_2_0 SkinnedAvatarVS();
		PixelShader = compile ps_2_0 SkinnedAvatarPSSmoke();
	}
}

technique TexAnim
{
	pass p0
	{
		VertexShader = compile vs_2_0 SkinnedAvatarVS();
		PixelShader = compile ps_2_0 SkinnedAvatarPSTracks();
	}
}
