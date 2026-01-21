#!/usr/bin/env python3
"""
Script to fix binary content types in swagger.json
Fixes cases where binary data (format: binary) is incorrectly specified as application/json
Changes them to appropriate binary content types (application/pdf, application/octet-stream, etc.)
"""

import json
import sys
from pathlib import Path
from typing import Dict, Any

def fix_binary_content_types(swagger: Dict[str, Any]) -> int:
    """
    Fix binary content types in swagger specification.
    Returns number of fixes made.
    """
    fixes_count = 0
    
    # Fix in paths
    paths = swagger.get('paths', {})
    for path, path_item in paths.items():
        for method, operation in path_item.items():
            if method not in ['get', 'post', 'put', 'patch', 'delete', 'head', 'options']:
                continue
            
            responses = operation.get('responses', {})
            if not responses:
                continue
            
            # Determine if this is a PDF endpoint based on path
            is_pdf = 'pdf' in path.lower() or ('download' in path.lower() and 'pdf' in operation.get('summary', '').lower())
            
            for status_code, response in responses.items():
                content = response.get('content', {})
                if not content:
                    continue
                
                # Check each content type
                for content_type, content_spec in list(content.items()):
                    schema = content_spec.get('schema', {})
                    # If schema has format: binary but content-type is application/json
                    if (schema.get('format') == 'binary' and 
                        content_type == 'application/json'):
                        
                        # Determine appropriate content type
                        if is_pdf:
                            new_content_type = 'application/pdf'
                        else:
                            new_content_type = 'application/octet-stream'
                        
                        # Remove old and add new
                        del content[content_type]
                        content[new_content_type] = content_spec
                        fixes_count += 1
                        print(f"  🔧 Fixed: {path} [{method.upper()}] {status_code}: {content_type} -> {new_content_type}")
    
    # Also fix in components/responses if they exist
    components = swagger.get('components', {})
    responses = components.get('responses', {})
    if responses:
        for response_name, response in responses.items():
            content = response.get('content', {})
            if not content:
                continue
            
            for content_type, content_spec in list(content.items()):
                schema = content_spec.get('schema', {})
                if (schema.get('format') == 'binary' and 
                    content_type == 'application/json'):
                    
                    del content[content_type]
                    content['application/octet-stream'] = content_spec
                    fixes_count += 1
                    print(f"  🔧 Fixed: components/responses/{response_name}: {content_type} -> application/octet-stream")
    
    return fixes_count

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 fix_binary_content_types.py <swagger.json>")
        sys.exit(1)
    
    swagger_file = Path(sys.argv[1])
    
    if not swagger_file.exists():
        print(f"Error: Swagger file not found: {swagger_file}")
        sys.exit(1)
    
    print("🔍 Checking for binary content type issues...")
    
    # Read swagger file
    with open(swagger_file, 'r', encoding='utf-8') as f:
        swagger = json.load(f)
    
    # Fix binary content types
    fixes_count = fix_binary_content_types(swagger)
    
    if fixes_count == 0:
        print("✅ No binary content type issues found")
        return
    
    # Create backup
    backup_file = swagger_file.with_suffix(f'.backup.{int(swagger_file.stat().st_mtime)}')
    import shutil
    shutil.copy2(swagger_file, backup_file)
    print(f"\n✅ Backup created: {backup_file.name}")
    
    # Write fixed swagger
    with open(swagger_file, 'w', encoding='utf-8') as f:
        json.dump(swagger, f, indent=2, ensure_ascii=False)
    
    print(f"\n✅ Fixed {fixes_count} binary content type issue(s)")
    print(f"💾 Updated: {swagger_file}")

if __name__ == '__main__':
    main()
