# Create a virtual environment
python -m venv venv

# Activate virtual environment on Windows
venv\Scripts\activate

# Activate on macOS/Linux
source venv/bin/activate

# Deavtivate environment
deactivate

pip install SomePackage            # latest version
pip install SomePackage==1.0.4     # specific version
pip install 'SomePackage>=1.0.4'     # minimum version

pip install -r requirements.txt

pip freeze > requirements.txt # update requirements list
