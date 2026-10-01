using System.Runtime.InteropServices;

#if UNITY_EDITOR
using UnityEditor;
#endif

public static class MacFileDialog
{
#if UNITY_STANDALONE_OSX && !UNITY_EDITOR
    [DllImport("FileDialog")]
    private static extern string OpenFilePanel(string title, string extension);
#endif

    public static string Open(string title, string extension = "")
    {
#if UNITY_EDITOR
        return EditorUtility.OpenFilePanel(title ?? string.Empty, string.Empty, extension ?? string.Empty);
#elif UNITY_STANDALONE_OSX
        return OpenFilePanel(title ?? string.Empty, extension ?? string.Empty);
#else
        return null;
#endif
    }
}
