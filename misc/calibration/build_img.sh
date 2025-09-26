#!/bin/bash

# Répertoire où les images seront sauvegardées
output_dir="./captures"
mkdir -p "$output_dir"

# Résolution maximale de la caméra (remplacez par la résolution souhaitée)
resolution="1920x1080"

# Nombre d'images à capturer
num_images=10

# Boucle pour capturer les images
for ((i=1; i<=num_images; i++))
do
    # Nom de fichier pour l'image
    filename="${output_dir}/image_${i}.jpg"
    
    # Message pour demander une pression de touche
    echo "Appuyez sur [Entrée] pour capturer l'image ${i}/${num_images}."
    
    # Attendre que l'utilisateur appuie sur [Entrée]
    read -p "Appuyez sur [Entrée] pour continuer..."
    
    # Capturer l'image
    fswebcam -r $resolution "$filename"
    
    # Afficher un message de confirmation
    echo "Captured $filename"
done

echo "Capture terminée. Toutes les images ont été prises."
