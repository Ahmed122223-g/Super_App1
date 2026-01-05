"""
Jiwar - Registration Code Generator Tool
=========================================

This tool allows the developer to generate registration codes
for doctors, pharmacies, and other admin types.

Usage: python generate_codes.py
"""

import os
import sys
import secrets
import string
from datetime import datetime

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

# Load environment variables
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env'))


def get_database_url():
    """Get codes database URL from environment"""
    url = os.getenv(
        'CODES_DB_URL',
        'postgresql://neondb_owner:npg_x59IiPwJkUAX@ep-round-queen-agum3qkg-pooler.c-2.eu-central-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require'
    )
    # Convert to psycopg driver format
    if url.startswith("postgresql://"):
        url = url.replace("postgresql://", "postgresql+psycopg://", 1)
    return url


def generate_random_code(length=10):
    """
    Generate a random alphanumeric code
    
    Args:
        length: Length of the code (default 10)
    
    Returns:
        Random string of uppercase letters and digits
    """
    characters = string.ascii_uppercase + string.digits
    return ''.join(secrets.choice(characters) for _ in range(length))


def get_code_model(code_type):
    """Get the appropriate SQLAlchemy model for the code type"""
    from app.models.codes import CODE_MODELS
    return CODE_MODELS.get(code_type)


def get_code_type_names():
    """Get available code types with Arabic names"""
    return {
        "1": ("doctor", "الأطباء"),
        "2": ("pharmacy", "الصيدليات"),
        "3": ("restaurant", "المطاعم"),
        "4": ("company", "الشركات"),
        "5": ("engineer", "المهندسين"),
        "6": ("mechanic", "الميكانيكيين"),
        "7": ("teacher", "المعلمين")
    }


def create_codes_table(engine, code_type):
    """Create the codes table if it doesn't exist"""
    from app.core.database import CodesBase
    # Import all code models to register them
    from app.models import codes
    CodesBase.metadata.create_all(bind=engine)


def save_codes_to_file(codes, code_type, output_dir):
    """
    Save generated codes to a text file
    
    Args:
        codes: List of generated codes
        code_type: Type of codes (doctor, pharmacy, etc.)
        output_dir: Directory to save the file
    """
    filename = f"{code_type}_codes.txt"
    filepath = os.path.join(output_dir, filename)
    
    # Create or append to file
    mode = 'a' if os.path.exists(filepath) else 'w'
    
    with open(filepath, mode, encoding='utf-8') as f:
        f.write(f"\n{'='*50}\n")
        f.write(f"Generated at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"{'='*50}\n")
        for code in codes:
            f.write(f"{code}\n")
    
    return filepath


def main():
    """Main interactive code generation function"""
    print("\n" + "="*60)
    print("    🔐 Jiwar - Registration Code Generator")
    print("="*60 + "\n")
    
    # Get code types
    code_types = get_code_type_names()
    
    print("📋 اختر نوع الأكواد التي تريد إنشاءها:\n")
    for key, (type_en, type_ar) in code_types.items():
        print(f"   {key}. {type_ar} ({type_en})")
    
    print()
    choice = input("👉 اختيارك (رقم): ").strip()
    
    if choice not in code_types:
        print("❌ اختيار غير صحيح!")
        return
    
    code_type, type_name = code_types[choice]
    print(f"\n✅ تم اختيار: {type_name}")
    
    # Get number of codes
    try:
        count = int(input("\n📊 كم كود تريد إنشاءه؟ ").strip())
        if count < 1 or count > 1000:
            print("❌ يجب أن يكون العدد بين 1 و 1000")
            return
    except ValueError:
        print("❌ يرجى إدخال رقم صحيح!")
        return
    
    # Ask about saving to file
    save_to_file = input("\n💾 هل تريد حفظ الأكواد في ملف نصي؟ (y/n): ").strip().lower()
    
    print("\n⏳ جاري إنشاء الأكواد...")
    
    # Generate codes
    generated_codes = [generate_random_code() for _ in range(count)]
    
    # Connect to database
    try:
        engine = create_engine(get_database_url())
        create_codes_table(engine, code_type)
        
        Session = sessionmaker(bind=engine)
        session = Session()
        
        # Get the appropriate model
        CodeModel = get_code_model(code_type)
        
        # Check for duplicates and insert
        inserted_count = 0
        for code in generated_codes:
            # Check if code already exists
            existing = session.query(CodeModel).filter(CodeModel.code == code).first()
            if not existing:
                new_code = CodeModel(code=code)
                session.add(new_code)
                inserted_count += 1
        
        session.commit()
        session.close()
        
        print(f"\n✅ تم رفع {inserted_count} كود إلى قاعدة البيانات")
        
    except Exception as e:
        print(f"\n⚠️ خطأ في قاعدة البيانات: {e}")
        print("   سيتم حفظ الأكواد في الملف فقط")
    
    # Save to file if requested
    if save_to_file == 'y':
        output_dir = os.path.dirname(os.path.abspath(__file__))
        filepath = save_codes_to_file(generated_codes, code_type, output_dir)
        print(f"📁 تم حفظ الأكواد في: {filepath}")
    
    # Display codes
    print(f"\n📋 الأكواد المُنشأة ({count}):\n")
    print("-" * 20)
    for code in generated_codes:
        print(f"   {code}")
    print("-" * 20)
    
    print("\n✨ تم بنجاح!\n")


if __name__ == "__main__":
    main()
