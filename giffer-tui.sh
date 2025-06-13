#!/bin/bash

# Interactive TUI mode
interactive_mode() {
   echo "=== Video to GIF Converter - Interactive Mode ==="
   
   read -p "Base Folder (source videos): " BASE_FOLDER
   while [ ! -d "$BASE_FOLDER" ]; do
       echo "Directory not found!"
       read -p "Base Folder (source videos): " BASE_FOLDER
   done
   
   read -p "Output Folder (for GIFs): " OUTPUT_FOLDER
   
   echo "Quality presets:"
   echo "  low    - 320px, 6fps, 0.5s segments"
   echo "  medium - 480px, 10fps, 1.0s segments"  
   echo "  high   - 720px, 15fps, 1.5s segments"
   read -p "Quality (low/medium/high): " QUALITY
   while [[ ! "$QUALITY" =~ ^(low|medium|high)$ ]]; do
       echo "Invalid quality! Use: low, medium, or high"
       read -p "Quality (low/medium/high): " QUALITY
   done
   
   read -p "File type [.mp4]: " FILE_TYPE
   FILE_TYPE="${FILE_TYPE:-.mp4}"
   
   read -p "Max file size in MB [unlimited]: " MAX_SIZE_MB
   MAX_SIZE_MB="${MAX_SIZE_MB:-999999}"
   
   echo ""
   echo "Settings:"
   echo "  Source: $BASE_FOLDER"
   echo "  Output: $OUTPUT_FOLDER" 
   echo "  Quality: $QUALITY"
   echo "  File type: $FILE_TYPE"
   echo "  Max size: ${MAX_SIZE_MB}MB"
   echo ""
   read -p "Continue? (y/n): " confirm
   
   if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
       echo "Cancelled."
       exit 0
   fi
}

# Quality-Presets
set_quality_preset() {
   case $1 in
       "low")
           VIDEO_WIDTH=320
           FPS=6
           SEGMENT_DURATION=0.5
           SUFFIX="-min"
           ;;
       "medium")
           VIDEO_WIDTH=480
           FPS=10
           SEGMENT_DURATION=1.0
           SUFFIX="-med"
           ;;
       "high")
           VIDEO_WIDTH=720
           FPS=15
           SEGMENT_DURATION=1.5
           SUFFIX="-high"
           ;;
       *)
           echo "Invalid quality preset: $1"
           echo "Available presets: low, medium, high"
           exit 1
           ;;
   esac
}

# Convert video to GIF
convert_video_to_gif() {
   local input_video="$1"
   local output_gif="$2"
   local duration="$3"
   
   # Zeitpunkte berechnen
   local begin=0
   local middle=$((duration / 2))
   local three_quarter=$((duration * 3 / 4))
   local end=$((duration - 2))
   
   # Spezifische Zeitpunkte definieren
   local times=($begin $middle $three_quarter $end)
   
   # 8 weitere gleichmäßig zwischen begin und end verteilen
   for i in $(seq 1 8); do
       local time=$((duration * i / 9))
       times+=($time)
   done
   
   # Sortieren der Zeitpunkte
   IFS=$'\n' times=($(sort -n <<<"${times[*]}"))
   
   # Filter für alle Segmente erstellen
   local filter_complex=""
   local concat_inputs=""
   
   for i in "${!times[@]}"; do
       local time=${times[$i]}
       filter_complex+="[0:v]trim=start=$time:duration=$SEGMENT_DURATION,setpts=PTS-STARTPTS,scale=$VIDEO_WIDTH:-1:flags=lanczos,fps=$FPS[v$i];"
       concat_inputs+="[v$i]"
   done
   
   filter_complex+="${concat_inputs}concat=n=${#times[@]}:v=1[out]"
   
   # FFmpeg ausführen
   ffmpeg -i "$input_video" -filter_complex "$filter_complex" -map "[out]" -y "$output_gif"
}

# Check for TUI mode
if [ "$1" = "-TUI" ]; then
   interactive_mode
else
   # Parameter prüfen
   if [ $# -lt 3 ] || [ $# -gt 5 ]; then
       echo "Usage: $0 <BaseFolder> <OutputFolder> <Quality> [FileType] [MaxSizeMB]"
       echo "       $0 -TUI (interactive mode)"
       echo "Quality: low, medium, high"
       echo "Example: $0 /videos /gifs medium .mp4 200"
       exit 1
   fi

   BASE_FOLDER="$1"
   OUTPUT_FOLDER="$2"
   QUALITY="$3"
   FILE_TYPE="${4:-.mp4}"
   MAX_SIZE_MB="${5:-999999}"
fi

# Quality-Preset setzen
set_quality_preset "$QUALITY"

# Maximalgröße in Bytes umrechnen
MAX_SIZE_BYTES=$((MAX_SIZE_MB * 1024 * 1024))

mkdir -p "$OUTPUT_FOLDER"

for video in "$BASE_FOLDER"/*"$FILE_TYPE"; do
   if [ -f "$video" ]; then
       # Dateigröße prüfen
       file_size=$(stat -f%z "$video" 2>/dev/null || stat -c%s "$video" 2>/dev/null)
       
       if [ "$file_size" -gt "$MAX_SIZE_BYTES" ]; then
           echo "Skipping $video ($(($file_size / 1024 / 1024))MB > ${MAX_SIZE_MB}MB)"
           continue
       fi
       
       filename=$(basename "$video" "$FILE_TYPE")
       output_gif="$OUTPUT_FOLDER/${filename}${SUFFIX}.gif"
       
       echo "Converting: $video -> $output_gif"
       
       # Video-Länge ermitteln
       duration=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$video")
       duration=${duration%.*}
       
       # Konvertierung durchführen
       convert_video_to_gif "$video" "$output_gif" "$duration"
   fi
done

echo "Conversion completed!"
