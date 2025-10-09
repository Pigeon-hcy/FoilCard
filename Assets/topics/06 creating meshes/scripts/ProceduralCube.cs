using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof (MeshFilter))]
[RequireComponent(typeof (MeshRenderer))]
public class ProceduralCube : MonoBehaviour {
    Mesh mesh;
    void Start() {
        MakeCube();



    }

    void MakeCube() {
        Vector3[] vertices = {
            new Vector3(0, 0, 0),
            new Vector3(1, 0, 0),
            new Vector3(1, 1, 0),
            new Vector3(0, 1, 0),
            new Vector3(0, 1, 1),
            new Vector3(1, 1, 1),
            new Vector3(1, 0, 1),
            new Vector3(0, 0, 1),
        };

        int[] triangles = {
            0,3,2,
            0,2,1, // -z
            3,4,5,
            3,5,2, // +y
            2,5,6,
            2,6,1, // +x
            7,4,3,
            7,3,0, // -x
            6,5,4,
            6,4,7, // -y
            7,0,1,
            7,1,6 //
        };

        mesh = GetComponent<MeshFilter>().mesh;
        mesh.Clear();
        mesh.vertices = vertices;
        mesh.triangles = triangles;
    }

    void OnDestroy() {
        Destroy(mesh);
    }
}