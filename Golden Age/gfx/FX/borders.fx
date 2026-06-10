// Parámetros optimizados
float4x4 WorldMatrix, ViewMatrix, ProjectionMatrix;
float2 TextureScale = float2(2048.0, 1024.0);
float3 BorderParams = float3(0.9375, 0.0625, 0.97); // .x=scale, .y=1/16, .z=offset

sampler BaseTexture2_0 = sampler_state {
    Texture = <tex0>;
    MinFilter = Point; MagFilter = Point; MipFilter = None;
    AddressU = Wrap; AddressV = Wrap;
};

sampler DirectionsTexture = sampler_state {
    Texture = <tex1>;
    MinFilter = Point; MagFilter = Point; MipFilter = None;
    AddressU = Wrap; AddressV = Wrap;
};

struct VS_OUTPUT_2_0 {
    float4 vPosition : POSITION;
    float2 vTexCoord0 : TEXCOORD0;
    float2 vTexCoord1 : TEXCOORD1;
};

VS_OUTPUT_2_0 VertexShader_Border_2_0(float4 Pos : POSITION, float2 UV : TEXCOORD0)
{
    VS_OUTPUT_2_0 Out;
    float4x4 WorldView = mul(WorldMatrix, ViewMatrix);
    Out.vPosition = mul(mul(Pos, WorldView), ProjectionMatrix);

    Out.vTexCoord0 = UV;

    // Optimizamos: movemos el escalado complejo aquí
    float2 tc = UV * TextureScale;
    tc = frac(tc); // 'frac' es mucho más eficiente que '%' (fmod)
    tc.x = (tc.x * BorderParams.x) * BorderParams.y;

    Out.vTexCoord1 = tc;
    return Out;
}

float4 PixelShader_Border_2_0(VS_OUTPUT_2_0 v) : COLOR
{
    float4 base = tex2D(BaseTexture2_0, v.vTexCoord0);

    // Usamos el resultado precalculado en el vertex shader
    float2 finalTC = v.vTexCoord1;
    finalTC.x += (base.b * BorderParams.z);

    float4 col = tex2D(DirectionsTexture, finalTC);
    col.r += base.r;
    return col;
}

technique BorderShader_2_0
{
    pass p0
    {
        ALPHABLENDENABLE = True;
        VertexShader = compile vs_2_0 VertexShader_Border_2_0();
        PixelShader = compile ps_2_0 PixelShader_Border_2_0();
    }
}
