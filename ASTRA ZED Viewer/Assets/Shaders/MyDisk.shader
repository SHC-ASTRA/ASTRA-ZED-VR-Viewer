//======= Copyright (c) Stereolabs Corporation, All rights reserved. ===============

Shader "MyDisk"
{
    Properties
    {
        _PointSize("Point Size", Float) = 0.05
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull Off
        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            #pragma vertex Vertex
            #pragma geometry Geometry
            #pragma fragment Fragment
            #pragma multi_compile_fog
            #include "MyDisk.cginc"
            ENDCG
        }
    }
}
