from requests_pkcs12 import post
import json
from pathlib import Path

# Settings
P12_FILE = 'client.p12'
P12_PASS = 'secretpassword'
URL = "https://myollama.example.com/api/generate"

payload = {
    "model": "mistral:7b",
    "prompt": "Write a one-sentence summary of what mTLS does.",
    "stream": True # Streaming is better for LLMs
}

# Get the repository root (2 levels up from this script)
REPO_ROOT = Path(__file__).resolve().parent.parent.parent

# Build the path to the certificate
CLIENT_P12_PATH = REPO_ROOT / "certs" / "client" / P12_FILE

try:
    # verify=True works because you bundled ca.crt into the .p12
    response = post(
        URL,
        json=payload,
        pkcs12_filename=CLIENT_P12_PATH,
        pkcs12_password=P12_PASS,
        verify=True, 
        stream=True
    )

    print("Ollama Response: ", end="", flush=True)
    for line in response.iter_lines():
        if line:
            chunk = json.loads(line)
            token = chunk.get('response', '')
            print(token, end='', flush=True)
            
            if chunk.get('done'):
                print("\n[Done]")

except Exception as e:
    print(f"\nConnection Error: {e}")