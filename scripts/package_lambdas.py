"""
Package Python Lambda Functions
Creates ZIP files with dependencies for deployment
"""

import shutil
import subprocess
import sys
import zipfile
from pathlib import Path


ROOT_DIR = Path(__file__).parent.parent
BUILD_DIR = ROOT_DIR / 'terraform' / 'lambdas'
TEMP_DIR = ROOT_DIR / '.temp'


def find_lambdas():
    """Find all Lambda function directories (those with handler.py)"""
    lambdas = []
    src_dir = ROOT_DIR / 'src'
    
    for handler_file in src_dir.rglob('handler.py'):
        lambda_dir = handler_file.parent
        relative_path = lambda_dir.relative_to(src_dir)
        lambdas.append(relative_path)
    
    return lambdas


def package_lambda(lambda_path):
    """Package a single Lambda function"""
    lambda_name = str(lambda_path).replace('/', '-')
    print(f'📦 Packaging {lambda_path}...')
    
    lambda_dir = ROOT_DIR / 'src' / lambda_path
    temp_dir = TEMP_DIR / lambda_path
    zip_file = BUILD_DIR / f'{lambda_name}.zip'
    
    # Clean temp directory
    if temp_dir.exists():
        shutil.rmtree(temp_dir)
    temp_dir.mkdir(parents=True)
    
    # Copy handler
    print('   📋 Copying handler...')
    shutil.copy(lambda_dir / 'handler.py', temp_dir / 'handler.py')
    
    # Install dependencies if requirements.txt exists
    requirements_file = lambda_dir / 'requirements.txt'
    if requirements_file.exists():
        print('   📦 Installing dependencies...')
        subprocess.run(
            ['pip', 'install', '-r', str(requirements_file), '-t', str(temp_dir), '--quiet'],
            check=True
        )
    
    # Create ZIP
    print('   🗜️  Creating ZIP archive...')
    with zipfile.ZipFile(zip_file, 'w', zipfile.ZIP_DEFLATED) as zf:
        for file in temp_dir.rglob('*'):
            if file.is_file():
                arcname = file.relative_to(temp_dir)
                zf.write(file, arcname)
    
    # Get size
    size_mb = zip_file.stat().st_size / (1024 * 1024)
    print(f'   ✅ Packaged: {zip_file} ({size_mb:.1f}M)')
    print('')


def main():
    """Main function"""
    print('🔍 Finding Python Lambda functions...')
    
    lambdas = find_lambdas()
    
    if not lambdas:
        print('⚠️  No Python Lambda functions found')
        return
    
    print(f'Found {len(lambdas)} Lambda function(s):')
    for lambda_path in lambdas:
        print(f'  - {lambda_path}')
    print('')
    
    # Create build directory
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    
    # Package each Lambda
    for lambda_path in lambdas:
        try:
            package_lambda(lambda_path)
        except Exception as e:
            print(f'❌ {lambda_path} - packaging failed: {e}')
            sys.exit(1)
    
    # Clean up
    if TEMP_DIR.exists():
        shutil.rmtree(TEMP_DIR)
    
    print('✨ All Lambda functions packaged successfully!')
    print('📁 Packages location: terraform/lambdas/')


if __name__ == '__main__':
    main()

