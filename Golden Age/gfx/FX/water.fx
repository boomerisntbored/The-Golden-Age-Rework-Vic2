texture tex0 < string name = "Base.tga"; >;	// Base texture
texture tex1 < string name = "Base.tga"; >;	// Base texture
texture tex2 < string name = "Base.tga"; >;	// Base texture
texture tex3 < string name = "Base.tga"; >;	// Base texture
texture tex4 < string name = "Base.tga"; >;	// Base texture
texture tex5 < string name = "Base.tga"; >;	// fow

float4x4 WorldViewProjectionMatrix;
float4x4 WorldMatrix;
float4x4 ViewProjectionMatrix;
float3	LightPosition;
float3	CameraPosition;
float	Time;
float	vAlpha;

#define FOW_SIZE_X 1024
#define FOW_SIZE_Y 512
const float WATER_RATION = 0.5;
const float MAIN_TILING_FACTOR = 0.25;
const float FADE_DISTANCE = 100;

sampler BaseTexture = sampler_state {
    Texture = <tex0>;
    MinFilter = Linear;
    MagFilter = Point;
    MipFilter = Linear;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler TheBackgroundTexture = sampler_state {
    Texture = <tex1>;
    MinFilter = Linear;
    MagFilter = Point;
    MipFilter = Linear;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler TerraIncognitaFiltered = sampler_state {
    Texture = <tex2>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
    AddressU = Mirror;
    AddressV = Mirror;
};

sampler WorldColor = sampler_state {
    Texture = <tex3>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler NormalMap = sampler_state {
    Texture = <tex4>;
    MinFilter = Linear;
    MagFilter = Point;
    MipFilter = Linear;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler Overlay = sampler_state {
    Texture = <tex4>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler WaterNormalMap = sampler_state {
    Texture = <tex0>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler FOWTexture = sampler_state {
    Texture = <tex5>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
    AddressU = Wrap;
    AddressV = Wrap;
};

struct VS_INPUT_WATER {
    float3 position			: POSITION;
    float2 texCoord0			: TEXCOORD0;
    float2 texCoord1			: TEXCOORD1;
    float2 texCoord2			: TEXCOORD2;
};

struct VS_OUTPUT_WATER {
    float4 position		: POSITION;
    float2 texCoord0		: TEXCOORD0;
    float3 eyeDirection		: TEXCOORD1;
    float3 lightDirection	: TEXCOORD2;
    float3 halfAngleDirection	: TEXCOORD3;
    float2 WorldTexture		: TEXCOORD4;
    float2 WorldTextureTI   : TEXCOORD5;
    float2 texCoord1		: TEXCOORD6;
	float  heightFactor			: TEXCOORD7;
};

const float3 offY = float3(0.11, 0.74, 0.43);
const float3 offZ = float3(0.47, 0.19, 0.78);

#define X_OFFSET 0.5
#define Z_OFFSET 0.5

float	ColorMapHeight;
float	ColorMapWidth;
float	ColorMapTextureHeight;
float	ColorMapTextureWidth;
float	MapWidth;
float	MapHeight;
float	BorderWidth;
float	BorderHeight;

VS_OUTPUT_WATER VertexShader_Water_2_0(const VS_INPUT_WATER IN) {
	VS_OUTPUT_WATER OUT = (VS_OUTPUT_WATER)0;
	float4 position = mul(float4(IN.position, 1.0), WorldViewProjectionMatrix);

	OUT.position = position;
	OUT.WorldTexture = IN.texCoord2;
	OUT.WorldTextureTI = IN.texCoord2;

 	float4 tangent = float4(1.0, 0.0, 0.0, 0.0);
	float4 normal = float4(0.0, 1.0, 0.0, 0.0);
	float4 biTangent = float4(0.0, 0.0, 1.0, 0.0);

	OUT.texCoord0 = IN.texCoord0 + Time * 0.02;

	float4 viewDir = float4(CameraPosition, 1.0) - position;
	OUT.eyeDirection.x = dot(viewDir, tangent);
	OUT.eyeDirection.y = dot(viewDir, normal);
	OUT.eyeDirection.z = dot(viewDir, biTangent);

	OUT.lightDirection.x = OUT.eyeDirection.x;
	OUT.lightDirection.y = OUT.eyeDirection.y;
	OUT.lightDirection.z = OUT.eyeDirection.z;

    OUT.halfAngleDirection.x = 0.5 * (position.z + position.x);
    OUT.halfAngleDirection.y = 0.5 * (position.z - position.y);
    OUT.halfAngleDirection.z = position.z;

    return OUT;
}

float4 PixelShader_Water_2_0(VS_OUTPUT_WATER IN) : COLOR {
	// Optimización radical: El shader original tenía un return temprano.
	// Todo el código matemático pesado de abajo fue eliminado ya que jamás se renderizaba.
	return tex2D(WorldColor, IN.WorldTexture);
}

VS_OUTPUT_WATER VertexShader_Water_1_1(const VS_INPUT_WATER IN) {
    VS_OUTPUT_WATER OUT = (VS_OUTPUT_WATER)0;
    float4 position = mul(float4(IN.position.xyz, 1.0), WorldViewProjectionMatrix);
    OUT.position = position;
    OUT.texCoord0 = IN.texCoord0 + Time * 0.1;

    float WorldPositionX = (ColorMapWidth * IN.texCoord1.x) / MapWidth;
	float WorldPositionY = (ColorMapHeight * IN.texCoord1.y) / MapHeight;
    OUT.WorldTexture.xy = float2((WorldPositionX + X_OFFSET) / ColorMapTextureWidth, (WorldPositionY + Z_OFFSET) / ColorMapTextureHeight);
    OUT.WorldTextureTI	= float2((IN.texCoord1.x + 0.25) / BorderWidth, (IN.texCoord1.y + 0.25) / BorderHeight);

	float3x3 objToTangentSpace;
	objToTangentSpace[0] = float3(1.0, 0.0, 0.0);
	objToTangentSpace[1] = float3(0.0, 0.0, 1.0);
	objToTangentSpace[2] = float3(0.0, 1.0, 0.0);

	float3 lightDir = normalize(LightPosition - CameraPosition);
	float3 viewDir = normalize(CameraPosition - IN.position.xyz);
    float3 halfAngleVector = normalize(lightDir + viewDir);

    OUT.lightDirection = normalize(mul(objToTangentSpace, lightDir.xyz)) * 0.5 + 0.5;
    OUT.halfAngleDirection = normalize(mul(objToTangentSpace, halfAngleVector.xyz)) * 0.5 + 0.5;

    return OUT;
}

float4 PixelShader_Water_1_1(VS_OUTPUT_WATER IN) : COLOR {
	float4 OutColor = float4(0.3, 0.3, 0.7, 1.0);
	float4 TerraIncognita = tex2D(TerraIncognitaFiltered, IN.WorldTextureTI);
	OutColor.rgba += (TerraIncognita.g - 0.25) * 1.33;
	return OutColor;
}

VS_OUTPUT_WATER VertexShader_HoiWater_2_0(const VS_INPUT_WATER IN) {
	VS_OUTPUT_WATER OUT = (VS_OUTPUT_WATER)0;
	float4 position = mul(float4(IN.position, 1.0), WorldViewProjectionMatrix);
	OUT.position = position;

	OUT.WorldTexture = IN.texCoord2;
	OUT.texCoord1 = IN.texCoord1;

 	float4 tangent = float4(1.0, 0.0, 0.0, 0.0);
	float4 normal = float4(0.0, 1.0, 0.0, 0.0);
	float4 biTangent = float4(0.0, 0.0, 1.0, 0.0);

	OUT.texCoord0 = IN.texCoord0 * MAIN_TILING_FACTOR + Time * 0.002;

	float4 viewDir = float4(0.0, 1.0, 1.0, 0.0);
	OUT.eyeDirection.x = dot(viewDir, tangent);
	OUT.eyeDirection.y = dot(viewDir, normal);
	OUT.eyeDirection.z = dot(viewDir, biTangent);

	OUT.lightDirection.x = OUT.eyeDirection.x;
	OUT.lightDirection.y = OUT.eyeDirection.y;
	OUT.lightDirection.z = OUT.eyeDirection.z;

	OUT.WorldTextureTI.x = (IN.texCoord2.x * ColorMapTextureWidth) / ColorMapWidth + (0.5 / FOW_SIZE_X);
	OUT.WorldTextureTI.y = (IN.texCoord2.y * ColorMapTextureHeight) / ColorMapHeight;

	OUT.heightFactor = 0.0;

	return OUT;
}

const float WRAP = 0.8;
const float WaveModOne = 3.0;
const float WaveModTwo = 4.0;
const float SpecValueOne = 8.0;
const float SpecValueTwo = 2.0;
const float vWaterTransparens = 0.7;
const float vColorMapFactor = 2.5;

float4 PixelShader_HoiWater_2_0(VS_OUTPUT_WATER IN) : COLOR {
	float2 coordB = IN.texCoord0.xy;
	float2 coordA = coordB * 3.0 + 0.1;
	coordB.y += 0.1;
	float2 coordC = coordB * 2.0;
	coordC.y += 0.05; // Ajuste simplificado de matemática repetida
	float2 coordD = coordB * 5.0;
	coordD.y += 0.2;

	float3 vBumpA = tex2D(WaterNormalMap, coordA);

	float timeOffset03 = 0.03 * Time;
	coordB.x += timeOffset03;
	coordB.y -= 0.02 * Time;
	float3 vBumpB = tex2D(WaterNormalMap, coordB);

	coordC.x += timeOffset03;
	coordC.y -= 0.01 * Time;
	float3 vBumpC = tex2D(WaterNormalMap, coordC);

	coordD.x += 0.02 * Time;
	coordD.y -= 0.01 * Time;
	float3 vBumpD = tex2D(WaterNormalMap, coordD);

	float3 vBumpTex = normalize(WaveModOne * (vBumpA + vBumpB + vBumpC + vBumpD) - WaveModTwo);
	float3 WorldColorColor = tex2D(WorldColor, IN.WorldTexture);

	float3 eyeDir = normalize(IN.eyeDirection);
	float NdotL = max(dot(eyeDir, (vBumpTex * 0.5)), 0.0);

	NdotL = saturate((NdotL + WRAP) * 0.55555); // 1 / (1 + WRAP) es aprox 0.55555
	// NdotL = lerp(NdotL, 1.0, IN.heightFactor); // heightFactor es 0, lerp no hace nada

	float3 OutColor = NdotL * (WorldColorColor * vColorMapFactor);

	float3 reflVector = -reflect(IN.lightDirection, vBumpTex);
	float specular = saturate(dot(normalize(reflVector), eyeDir));

	specular = pow(specular, SpecValueOne);
	OutColor += (specular * 0.5); // Dividir por 2 es multiplicar por 0.5

	float xoffset = 0.5 / FOW_SIZE_X;
	float yoffset = 0.5 / FOW_SIZE_Y;

	// FOW (Fog of war)
	float FOW = tex2D(FOWTexture, IN.WorldTextureTI + float2(-xoffset, yoffset)).b;
	FOW += tex2D(FOWTexture, IN.WorldTextureTI + float2(xoffset, yoffset)).b;
	FOW += tex2D(FOWTexture, IN.WorldTextureTI + float2(-xoffset, -yoffset)).b;
	FOW += tex2D(FOWTexture, IN.WorldTextureTI + float2(xoffset, -yoffset)).b;

	FOW = saturate(FOW * 0.5 - 1.0);
	FOW = saturate(FOW + 0.5);

	OutColor = lerp(OutColor, OutColor.bbb, 0.3);

	// Combinación de operaciones aritméticas fijas en un solo paso vectorizado para la GPU
	OutColor = (OutColor + float3(0.17, 0.15, 0.12)) / float3(1.998, 2.2275, 2.4975); // Multiplicación de divisores precalculados

	return float4(OutColor * FOW, vWaterTransparens);
}

technique WaterShader_2_0 {
	pass p0 {
		ALPHABLENDENABLE = True;
		VertexShader = compile vs_2_0 VertexShader_Water_2_0();
		PixelShader = compile ps_2_0 PixelShader_Water_2_0();
	}
}

technique WaterShader_1_1 {
	pass p0 {
		ALPHABLENDENABLE = True;
		VertexShader = compile vs_1_1 VertexShader_Water_1_1();
		PixelShader = compile ps_2_0 PixelShader_Water_1_1();
	}
}

technique HoiWaterShader_2_0 {
	pass p0 {
		ALPHATESTENABLE = True;
		ALPHABLENDENABLE = True;
		VertexShader = compile vs_2_0 VertexShader_HoiWater_2_0();
		PixelShader = compile ps_2_0 PixelShader_HoiWater_2_0();
	}
}

struct VS_INPUT_WATER_FAR {
    float4 position_uv		: POSITION;
};

struct VS_OUTPUT_WATER_FAR {
    float4 position			: POSITION;
	float2 vWorldPos		: TEXCOORD0;
	float2 vUV				: TEXCOORD1;
};

VS_OUTPUT_WATER_FAR VertexShader_Far(const VS_INPUT_WATER_FAR IN) {
	VS_OUTPUT_WATER_FAR OUT = (VS_OUTPUT_WATER_FAR)0;
	float2 pos = IN.position_uv.xy - CameraPosition.xz;
	OUT.position = mul(float4(pos.x, 0.2, pos.y, 1.0), ViewProjectionMatrix);
	OUT.vWorldPos = IN.position_uv.xy * 0.001953125; // 1 / 512.0 precalculado
	OUT.vUV = IN.position_uv.zw;
	return OUT;
}

float4 PixelShader_Far(VS_OUTPUT_WATER_FAR IN) : COLOR {
	float4 color = tex2D(WorldColor, IN.vUV);
	float alpha = color.a;

	float contour_darken = smoothstep(0.0, 0.08, abs(0.2 - alpha)) * smoothstep(0.0, 0.11, abs(0.525 - alpha)) * smoothstep(0.0, 0.06, abs(0.85 - alpha)) +
	                       step(0.6851, IN.vUV.x) + step(IN.vUV.x, 0.0001);

	float4 overlay = tex2D(Overlay, IN.vWorldPos);
	float4 OutColor = lerp(color, overlay, 0.6);

	OutColor.rgb = (OutColor.rgb + float3(0.17, 0.15, 0.12)) / float3(1.998, 2.2275, 2.4975);

	return OutColor * saturate(contour_darken * 0.6 + 0.4);
}

technique WaterShaderFar {
	pass p0 {
		ALPHATESTENABLE = False;
		ALPHABLENDENABLE = False;
		VertexShader = compile vs_3_0 VertexShader_Far();
		PixelShader = compile ps_3_0 PixelShader_Far();
	}
}
