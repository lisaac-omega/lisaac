#include <GLFW/glfw3.h>
#include "nanovg.h"
#define NANOVG_GL3_IMPLEMENTATION
#include "nanovg_gl.h"

int main() {
    // Initialise GLFW
    if (!glfwInit()) {
        return -1;
    }

    // Créez la première fenêtre GLFW
    GLFWwindow* window1 = glfwCreateWindow(640, 480, "Fenêtre 1", NULL, NULL);
    if (!window1) {
        glfwTerminate();
        return -1;
    }

    // Créez la deuxième fenêtre GLFW
    GLFWwindow* window2 = glfwCreateWindow(640, 480, "Fenêtre 2", NULL, NULL);
    if (!window2) {
        glfwTerminate();
        return -1;
    }

    // Activez le contexte de la première fenêtre
    glfwMakeContextCurrent(window1);

    // Initialisez NanoVG pour la première fenêtre
    NVGcontext* vg1 = nvgCreateGL3(NVG_ANTIALIAS);

    // Activez le contexte de la deuxième fenêtre
    glfwMakeContextCurrent(window2);

    // Initialisez NanoVG pour la deuxième fenêtre
    NVGcontext* vg2 = nvgCreateGL3(NVG_ANTIALIAS);

    // Boucle principale
    while (!glfwWindowShouldClose(window1) && !glfwWindowShouldClose(window2)) {
        // Rendu pour la première fenêtre
        glfwMakeContextCurrent(window1);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        // Utilisez NanoVG pour dessiner dans la première fenêtre (vg1)
        nvgBeginFrame(vg1, 640, 480, 1);

        // Dessinez une ligne traversant la première fenêtre
        nvgBeginPath(vg1);
        nvgMoveTo(vg1, 100, 100);
        nvgLineTo(vg1, 540, 380);
        nvgStrokeColor(vg1, nvgRGB(255, 0, 0)); // Couleur rouge
        nvgStrokeWidth(vg1, 2.0f);
        nvgStroke(vg1);

        nvgEndFrame(vg1);

        glfwSwapBuffers(window1);

        // Rendu pour la deuxième fenêtre
        glfwMakeContextCurrent(window2);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        // Utilisez NanoVG pour dessiner dans la deuxième fenêtre (vg2)
        nvgBeginFrame(vg2, 640, 480, 1);

        // Dessinez une ligne traversant la deuxième fenêtre
        nvgBeginPath(vg2);
        nvgMoveTo(vg2, 100, 100);
        nvgLineTo(vg2, 540, 380);
        nvgStrokeColor(vg2, nvgRGB(0, 0, 255)); // Couleur bleue
        nvgStrokeWidth(vg2, 2.0f);
        nvgStroke(vg2);

        nvgEndFrame(vg2);

        glfwSwapBuffers(window2);

        // Gérez les événements GLFW, tels que la fermeture de fenêtre, etc.
        glfwPollEvents();
    }

    // Nettoyage
    nvgDeleteGL3(vg1);
    nvgDeleteGL3(vg2);

    glfwDestroyWindow(window1);
    glfwDestroyWindow(window2);

    glfwTerminate();

    return 0;
}
