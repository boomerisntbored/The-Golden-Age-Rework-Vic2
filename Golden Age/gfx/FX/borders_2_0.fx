// --- Parámetros de entrada ---
float4x4 WorldViewProjectionMatrix; // Multiplica esto en la CPU: World * View * Projection
float2   TextureScaleParams;        // .x = ColorMapWidth/MapWidth, .y = ColorMapHeight/MapHeight
float2   BorderScaleParams;         // .x = BorderTextureWidth, .y = BorderTextureHeight

// --- Texturas ---
texture tex0 < string ResourceName = "borders.tga"; >;
texture tex1 < string ResourceName = "borderDirections.tga"; >;
texture tex2 < string ResourceName = "TerraIncog.tga"; >;
texture tex3 < string ResourceName = "Diag.tga"; >;
texture tex4 < string ResourceName = "ColorWater.tga"; >;

sampler BaseTexture = sampler_state { Texture = <tex0>; MinFilter = Point; MagFilter = Point; AddressU = Clamp; AddressV = Clamp; };
sampler ProvinceBorderTexture = sampler_state { Texture = <tex1>; MinFilter = Linear; MagFilter = Linear; AddressU = Clamp; AddressV = Clamp; };
sampler TerraIncognitaFiltered = sampler_state { Texture = <tex2>; MinFilter = Linear; MagFilter = Linear; AddressU = Clamp; AddressV = Clamp; };
sampler ProvinceBorderDiagTexture = sampler_state { Texture = <tex3>; MinFilter = Point; MagFilter = Point; AddressU = Clamp; AddressV = Clamp; };
sampler ColorWaterTexture = sampler_state { Texture = <tex4>; MinFilter = Linear; MagFilter = Linear; AddressU = Clamp; AddressV = Clamp; };

// --- Estructuras ---
struct VS_INPUT { float4 vPosition : POSITION; float2 vTexCoord : TEXCOORD0; };
struct VS_OUTPUT { float4 vPosition : POSITION; float2 vTexCoord0 : TEXCOORD0; float2 vTexCoord1 : TEXCOORD1; float2 vColorTex : TEXCOORD2; };
struct VS_WATERINPUT { float4 vPosition : POSITION; float2 vProvCoord : TEXCOORD0; float2 vDiagCoord : TEXCOORD1; };
struct VS_WATEROUTPUT { float4 vPosition : POSITION; float2 vProvCoord : TEXCOORD0; float2 vDiagCoord : TEXCOORD1; };

// --- Vertex Shaders ---
VS_OUTPUT VertexShader_Border(const VS_INPUT v)
{
    VS_OUTPUT Out;
    Out.vPosition = mul(v.vPosition, WorldViewProjectionMatrix);
    Out.vTexCoord0 = v.vTexCoord + float2(0.0f, 0.0075f);
    Out.vColorTex = Out.vTexCoord0 * TextureScaleParams;
    Out.vTexCoord1 = (v.vTexCoord + float2(0.0f, 0.0293f)) * BorderScaleParams;
    return Out;
}

VS_WATEROUTPUT VertexShader_WaterBorder(const VS_WATERINPUT v)
{
    VS_WATEROUTPUT Out;
    float4 P = float4(v.vPosition.x, 0.0f, v.vPosition.y - 0.7f, 1.0f);
    Out.vPosition = mul(P, WorldViewProjectionMatrix);
    Out.vPosition.y += 2.0f;
    Out.vProvCoord = v.vProvCoord;
    Out.vDiagCoord = v.vDiagCoord;
    return Out;
}

// --- Pixel Shaders ---
float4 PixelShader_ProvinceBorder(VS_OUTPUT v) : COLOR
{
    float4 Base = tex2D(BaseTexture, v.vTexCoord0);
    float2 TC = frac(v.vTexCoord1);
    TC.y = 1.0f - TC.y;
    TC.x = (TC.x * 0.05f) + Base.b;

    float4 Color = tex2D(ProvinceBorderTexture, TC);
    float4 Diag = tex2D(ProvinceBorderDiagTexture, TC + (Base.a - Base.b));

    Color.rgb = max(Diag.rgb * Diag.a, Color.rgb * Color.a);
    Color.a = max(Color.a, Diag.a);
    Color.rgb += (tex2D(TerraIncognitaFiltered, v.vTexCoord0).g - 0.25f) * 1.33f;
    Color.rgb += tex2D(ColorWaterTexture, v.vColorTex).aaa;
    return Color;
}

float4 PixelShader_CountryBorder(VS_OUTPUT v) : COLOR
{
    float2 TC = frac(v.vTexCoord1);
    TC.x = (TC.x * 0.05859375f) + (tex2D(BaseTexture, v.vTexCoord0).r * 0.97f);
    return tex2D(ProvinceBorderTexture, TC);
}

float4 PixelShader_River(VS_OUTPUT v) : COLOR
{
    float2 TC = frac(v.vTexCoord1);
    TC.x = (TC.x * 0.05859375f) + (tex2D(BaseTexture, v.vTexCoord0).g * 0.99f);
    return tex2D(ProvinceBorderTexture, TC);
}

float4 PixelShader_WaterBorder(VS_WATEROUTPUT v) : COLOR
{
    float4 C = tex2D(ProvinceBorderTexture, v.vProvCoord);
    float4 D = tex2D(ProvinceBorderDiagTexture, v.vDiagCoord);
    C.rgb = max(D.rgb * D.a, C.rgb * C.a);
    C.a = max(C.a, D.a);
    return C;
}

// --- Técnicas ---
technique ProvinceBorderShader { pass p0 { ALPHABLENDENABLE = True; VertexShader = compile vs_2_0 VertexShader_Border(); PixelShader = compile ps_2_0 PixelShader_ProvinceBorder(); } }
technique CountryBorderShader { pass p0 { ALPHABLENDENABLE = True; VertexShader = compile vs_2_0 VertexShader_Border(); PixelShader = compile ps_2_0 PixelShader_CountryBorder(); } }
technique RiverShader { pass p0 { ALPHABLENDENABLE = True; VertexShader = compile vs_2_0 VertexShader_Border(); PixelShader = compile ps_2_0 PixelShader_River(); } }
technique WaterBorderShader { pass p0 { ALPHABLENDENABLE = True; VertexShader = compile vs_2_0 VertexShader_WaterBorder(); PixelShader = compile ps_2_0 PixelShader_WaterBorder(); } }
