
import re
import os
import base64
import requests

# Configuration
SOURCE_FILE = r"C:\Users\akith\.gemini\antigravity\brain\3686ee3c-1203-4b48-9ad2-0d32ebf69a38\sequence_diagrams.md"
OUTPUT_DIR = r"d:\apiit\A second year\cc\second sem\Midwife_sys\final_diagrams"

def ensure_dir(directory):
    if not os.path.exists(directory):
        os.makedirs(directory)

def download_image(mermaid_code, filename):
    # Prepare the graph definition
    graph = mermaid_code.strip()
    
    # Encode for mermaid.ink
    graphbytes = graph.encode("utf8")
    base64_bytes = base64.urlsafe_b64encode(graphbytes)
    base64_string = base64_bytes.decode("ascii")
    
    url = "https://mermaid.ink/img/" + base64_string
    
    try:
        print(f"Downloading {filename}...")
        response = requests.get(url)
        if response.status_code == 200:
            with open(filename, 'wb') as f:
                f.write(response.content)
            print(f"Saved: {filename}")
        else:
            print(f"Failed to download {filename}: Status {response.status_code}")
    except Exception as e:
        print(f"Error downloading {filename}: {e}")

def main():
    ensure_dir(OUTPUT_DIR)
    
    with open(SOURCE_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    # Regex to find mermaid blocks and preceding headers
    # Looking for '## Title' followed eventually by '```mermaid ... ```'
    
    # Simple split by "```mermaid"
    parts = content.split("```mermaid")
    
    # The first part is preamble, ignore test
    for i, part in enumerate(parts[1:], 1):
        # The content of the diagram is until the next "```"
        if "```" in part:
            diagram_code = part.split("```")[0]
            
            # Try to find a meaningful name from the text BEFORE this block in the original file
            # This is a bit tricky with split, but we can name them sequentially for safety
            
            # Better approach: Scan the original content for headers
            pass

    # Re-approaching parsing to capture headers
    # We will iterate through lines to find Headers and Code Blocks
    
    lines = content.splitlines()
    current_title = "diagram"
    counter = 1
    
    in_block = False
    block_lines = []
    
    for line in lines:
        if line.startswith("### "):
            # Subheading, e.g. "1.1 Midwife Login"
            clean_title = line.replace("### ", "").strip().replace(" ", "_").replace("/", "-").lower()
            current_title = clean_title
        elif line.startswith("## "):
            # Main Heading
            clean_title = line.replace("## ", "").strip().replace(" ", "_").replace("/", "-").lower()
            current_title = clean_title
            
        if line.strip() == "```mermaid":
            in_block = True
            block_lines = []
            continue
            
        if line.strip() == "```" and in_block:
            in_block = False
            if block_lines:
                filename = os.path.join(OUTPUT_DIR, f"{counter:02d}_{current_title}.png")
                download_image("\n".join(block_lines), filename)
                counter += 1
            continue
            
        if in_block:
            block_lines.append(line)

if __name__ == "__main__":
    main()
