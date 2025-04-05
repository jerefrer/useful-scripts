import re
import pandas as pd
import argparse

def parse_srt(file_path):
    """
    Parse an SRT file and return a list of subtitle entries.
    Each entry contains: number, begin time, end time, and text.
    """
    with open(file_path, 'r', encoding='utf-8-sig') as file:
        content = file.read()
    
    # Pattern to match subtitle entries
    pattern = r'(\d+)\n(\d{2}:\d{2}:\d{2},\d{3}) --> (\d{2}:\d{2}:\d{2},\d{3})\n((?:.+\n)+)'
    matches = re.findall(pattern, content)
    
    subtitles = []
    for match in matches:
        number = int(match[0])
        begin_time = match[1]
        end_time = match[2]
        text = match[3].strip()
        
        subtitles.append({
            'Number': number,
            'Begin': begin_time,
            'End': end_time,
            'Text': text
        })
    
    return subtitles

def convert_srt_to_excel(srt_file, excel_file):
    """
    Convert an SRT file to Excel format with columns:
    Number, Begin, End, Text
    """
    subtitles = parse_srt(srt_file)
    
    # Create DataFrame
    df = pd.DataFrame(subtitles)
    
    # Write to Excel
    df.to_excel(excel_file, index=False)
    print(f"Conversion complete! Excel file saved to {excel_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Convert SRT file to Excel')
    parser.add_argument('srt_file', help='Path to the SRT file')
    parser.add_argument('--output', '-o', default=None, help='Output Excel file path (default: input filename with .xlsx extension)')
    
    args = parser.parse_args()
    
    # If output filename not provided, use input filename with .xlsx extension
    if args.output is None:
        args.output = args.srt_file.rsplit('.', 1)[0] + '.xlsx'
    
    convert_srt_to_excel(args.srt_file, args.output)