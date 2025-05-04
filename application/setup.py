from setuptools import setup, find_packages

setup(
    name="book-library-api",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[
        "fastapi[standard]==0.115.12",
        "fastapi-cli==0.0.7",
        "uvicorn==0.34.2",
        "python-jose[cryptography]==3.4.0",
        "passlib[bcrypt]==1.7.4",
        "pydantic==2.11.3",
        "bcrypt==3.2.2",
        "psutil==5.9.8"
    ],
    author="Shubham Kumar",
    author_email="your.email@example.com",
    description="A FastAPI-based book library API with authentication and role-based authorization",
    long_description=open("README.md").read() if open("README.md") else "",
    long_description_content_type="text/markdown",
    keywords="fastapi, books, api, authentication",
    url="https://github.com/yourusername/book-library-api",
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
    ],
    python_requires=">=3.8",
)