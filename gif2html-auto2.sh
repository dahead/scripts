#!/bin/bash

# Generate HTML gallery from existing GIFs
generate_html_gallery() {
   local base_folder="$1"
   local html_filename="${2:-gallery.html}"
   local html_file="$base_folder/$html_filename"
   
   if [ ! -d "$base_folder" ]; then
       echo "Error: Directory '$base_folder' not found!"
       exit 1
   fi
   
   # Check if there are any GIF files
   if ! ls "$base_folder"/*.gif >/dev/null 2>&1; then
       echo "No GIF files found in '$base_folder'"
       exit 1
   fi
   
   cat > "$html_file" << 'EOF'
<!DOCTYPE html>
<html>
<head>
   <title>GIF Gallery</title>
   <style>
       body { font-family: Arial, sans-serif; margin: 20px; }
       .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px; }
       .item { border: 1px solid #ddd; padding: 15px; text-align: center; cursor: pointer; }
       .item img { max-width: 100%; height: auto; }
       .gif-container { position: relative; }
       .gif-static { display: block; }
       .gif-animated { display: none; }
   </style>
   <script>
       function playGif(container) {
           const staticImg = container.querySelector('.gif-static');
           const animatedImg = container.querySelector('.gif-animated');
           staticImg.style.display = 'none';
           animatedImg.style.display = 'block';
       }
       
       function pauseGif(container) {
           const staticImg = container.querySelector('.gif-static');
           const animatedImg = container.querySelector('.gif-animated');
           staticImg.style.display = 'block';
           animatedImg.style.display = 'none';
       }
   </script>
</head>
<body>
   <h1>GIF Gallery</h1>
   <div class="grid">
EOF

   # Add each GIF to the HTML
   for gif_path in "$base_folder"/*.gif; do
       if [ -f "$gif_path" ]; then
           local gif_name=$(basename "$gif_path")
           
           cat >> "$html_file" << EOF
       <div class="item">
           <div class="gif-container" onmouseenter="playGif(this)" onmouseleave="pauseGif(this)">
               <img class="gif-static" src="$gif_name" alt="$gif_name">
               <img class="gif-animated" src="$gif_name" alt="$gif_name">
           </div>
           <p><strong>$gif_name</strong></p>
       </div>
EOF
       fi
   done

   cat >> "$html_file" << 'EOF'
   </div>
</body>
</html>
EOF

   echo "HTML gallery created: $html_file"
}

# Check parameters
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
   echo "Usage: $0 <GIF_folder> [html_filename]"
   echo "Example: $0 /path/to/gifs"
   echo "Example: $0 /path/to/gifs my_gallery.html"
   exit 1
fi

GIF_FOLDER="$1"
HTML_FILENAME="${2:-gallery.html}"

generate_html_gallery "$GIF_FOLDER" "$HTML_FILENAME"
