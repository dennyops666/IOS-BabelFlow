import os
import requests
from openai import OpenAI
from PIL import Image
from io import BytesIO
import json
import numpy as np

def get_api_key():
    try:
        with open('config.json', 'r') as f:
            config = json.load(f)
            return config.get('OPENAI_API_KEY')
    except FileNotFoundError:
        return os.getenv('OPENAI_API_KEY')

def remove_padding(image):
    # 将图像转换为RGBA模式
    image = image.convert('RGBA')
    
    # 获取图像数据
    data = np.array(image)
    
    # 创建alpha蒙版
    alpha = data[:, :, 3]
    
    # 找到非透明像素的边界（使用极低的阈值）
    rows = np.any(alpha > 1, axis=1)  # 极低的阈值
    cols = np.any(alpha > 1, axis=0)
    ymin, ymax = np.where(rows)[0][[0, -1]]
    xmin, xmax = np.where(cols)[0][[0, -1]]
    
    # 计算中心点
    center_x = (xmin + xmax) // 2
    center_y = (ymin + ymax) // 2
    
    # 计算最小尺寸（取较小的维度）
    size = min(xmax - xmin, ymax - ymin)
    
    # 确保裁剪区域是正方形，并且尽可能小
    half_size = size // 3  # 减小裁剪区域
    crop_xmin = center_x - half_size
    crop_ymin = center_y - half_size
    crop_xmax = center_x + half_size
    crop_ymax = center_y + half_size
    
    # 裁剪图像
    cropped = image.crop((crop_xmin, crop_ymin, crop_xmax, crop_ymax))
    
    # 调整大小到1024x1024
    resized = cropped.resize((1024, 1024), Image.Resampling.LANCZOS)
    
    return resized

def generate_app_icon():
    # 初始化 OpenAI 客户端
    client = OpenAI(api_key=get_api_key())

    # 图标描述
    prompt = """Create a fully visible, 3D translation app icon with these EXACT requirements:
    1. Core Design - FULLY VISIBLE:
       - Two 3D speech bubbles positioned to fit entirely within canvas
       - Left bubble with 'A', right bubble with 'B'
       - Bubbles sized to 80% of canvas width to ensure full visibility
       - Clear spacing between bubbles
       - No cropping of main elements
    2. 3D Layout - Complete View:
       - Bubbles floating above platform
       - Platform contained within bottom 20% of canvas
       - All edges and corners must be fully visible
       - 30-degree viewing angle for optimal depth
       - Equal spacing from canvas edges
    3. Premium 3D Materials:
       - Bubbles: High-gloss white ceramic (#FFFFFF)
       - Letters: Deep metallic blue (#0D47A1 to #40C4FF gradient)
       - Platform: Frosted glass with subtle glow
       - Edges: Polished chrome with highlights
       - Surfaces: Smooth with subtle reflections
    4. Professional Lighting:
       - Main light: 45° top-right
       - Fill light: Soft left side
       - Rim light: Bottom edge glow
       - Sharp highlights on curves
       - Soft shadows under bubbles
    5. Color Details:
       - Main white: Pure ceramic (#FFFFFF)
       - Primary blue: OpenAI gradient (#00A67E to #40C4FF)
       - Accent: Electric blue rim (#40C4FF)
       - Shadow: Soft tech blue (#0D47A1)
       - Glow: Subtle cyan (#E0FFFF)
    6. Critical Requirements:
       - ALL elements must be 100% visible
       - NO cropping of any design elements
       - Strong 3D depth while maintaining full visibility
       - Clean, premium look
       - Easy to spot on home screen
       - Professional tech aesthetic
    7. Specific Measurements:
       - Bubbles: 80% of canvas width
       - Platform: 90% of canvas width
       - Vertical spacing: 10% margins top and bottom
       - Horizontal spacing: 10% margins left and right
       - 3D depth: 40px extrusion"""

    try:
        # 生成图像
        response = client.images.generate(
            model="dall-e-3",
            prompt=prompt,
            size="1024x1024",
            quality="hd",
            n=1,
        )

        # 获取图像 URL
        image_url = response.data[0].url
        
        # 下载图像
        response = requests.get(image_url)
        image = Image.open(BytesIO(response.content))
        
        # 去除padding并调整大小
        image = remove_padding(image)

        # 创建 Assets.xcassets/AppIcon.appiconset 目录
        base_path = "IOS-BabelFlow/Assets.xcassets/AppIcon.appiconset"
        os.makedirs(base_path, exist_ok=True)

        # 保存处理后的图像
        original_path = os.path.join(base_path, "icon_1024x1024.png")
        image.save(original_path, "PNG")

        # 创建 Contents.json 文件
        contents = {
            "images": [
                {
                    "filename": "icon_1024x1024.png",
                    "idiom": "universal",
                    "platform": "ios",
                    "size": "1024x1024"
                }
            ],
            "info": {
                "author": "xcode",
                "version": 1
            }
        }

        with open(os.path.join(base_path, "Contents.json"), "w") as f:
            json.dump(contents, f, indent=2)

        print(f"App icon generated successfully and saved to {original_path}")
        print("Please open your Xcode project to see the new icon")

    except Exception as e:
        print(f"Error generating app icon: {str(e)}")

if __name__ == "__main__":
    generate_app_icon()
