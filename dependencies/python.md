# Python Dependencies

## Dependency Audit

##### Appropriateness
:heavy_check_mark: Well suited for the purpose it is being used for

:heavy_multiplication_x: Not used, not a production dependency, or not well suited, or has a better alternative

##### Support
:heavy_check_mark: Industry Standard with regular releases and a large community

:heavy_check_mark:\* Dependency is supported but pinned version is out of date

:heavy_multiplication_x: No recent release or no community of users/maintainers


Dependency | Version | Appropriateness | Support |
--- | --- | --- | --- |
python | 3.11.4 | :heavy_check_mark: | :heavy_check_mark:\* |
uvicorn[standard] | ^0.23.2 | :heavy_check_mark: | :heavy_check_mark: |
pytest | ^7.4.1 | :heavy_multiplication_x: | :heavy_check_mark:\* |
httpx | ^0.24.1 | :heavy_multiplication_x: | |
alembic | ^1.12.0 |:heavy_check_mark: | :heavy_check_mark: | 
psycopg2-binary | ^2.9.9 | :heavy_multiplication_x: | |
pydantic-settings | ^2.0.3 | :heavy_check_mark: | :heavy_check_mark: |
pytz | ^2023.3.post1 | :heavy_multiplication_x: | |
sqlalchemy-utils | ^0.41.1 | :heavy_check_mark: | :heavy_check_mark:\* |
pytest-html | ^4.1.1 | :heavy_multiplication_x: | |
python-dotenv | ^1.0.1 | :heavy_multiplication_x: | |
sqlalchemyseed | ^2.0.0 | :heavy_check_mark: | :heavy_multiplication_x: |
python3-saml | 1.16.0 | :heavy_check_mark: | :heavy_check_mark: | 
pyjwt | ^2.8.0 | :heavy_check_mark: | :heavy_check_mark: |
python-multipart | ^0.0.9 | :heavy_check_mark: | :heavy_check_mark:\* |
pandas | ^2.2.2 | :heavy_multiplication_x: | :heavy_check_mark: |
openpyxl | ^3.1.5 | :heavy_check_mark: | :heavy_check_mark: |
sqltap | ^0.3.11 | :heavy_check_mark: | :heavy_multiplication_x: |
fastapi-pagination | 0.12.34 | :heavy_check_mark: | :heavy_check_mark:\* |
sqlmodel | 0.0.22 | :heavy_check_mark: | :heavy_check_mark:\* | 
fastapi | 0.115.8 | :heavy_check_mark: | :heavy_check_mark:\* |
debugpy | 1.8.12 | :heavy_multiplication_x: | |
setuptools-scm | 8.0.4 | :heavy_multiplication_x: | |
gunicorn | ^23.0.0 | :heavy_multiplication_x: | :heavy_check_mark: |
httptools | ^0.6.4 | :heavy_multiplication_x:| :heavy_check_mark: |


## Dependencies Summary

#### The good
Poetry + FastAPI + SQLModel + Uvicorn is both a modern and mature stack for building a python web service in 2025.
I have a lot of confidence in these choices.

#### The ok but notable

sqltap and sqlalchemyseed are neat libraries that are no longer supported with no clear alternative.
There is no security risk to continuing to include them (except supply chain attacks).
They are not performing a mission critial function either.
They're safe to continue using until they break.

Pytz, httpx, and python-dotenv are either not being utilized or can be removed easily.

SQLAlchemy is not directly depended upon. There were major breaking changes between 1.3 and 2.0.
A version specifier of >2.0 should be explicitly added to make sure compatibility issues do not crop up.

Pandas should not be used syncronously in a web application.
Alternatives for the bulk_import process should be investigated.

Dependency versions have been specified using the caret (^) operator.
This [pins the leftmost version number](https://python-poetry.org/docs/dependency-specification/#caret-requirements) which prevents breaking changes from being installed while still taking security fixes.
For the most part, this is the desired behavior but dependencies _do need_ to be explicitly upgraded at regular intervals to stay up to date.

#### Areas of improvement

Dependency versions have been pinned to versions without security updates.
These must be unpinned and allowed to receive security updates.

Pytest, debugpy, setuptools-scm are not production dependencies.
These should be re-installed using poetry's dependency groups functionality to add them in a dev group.
Black, flake8, isort, and mypy are used in the .pre-commit-config.yaml file. These should be installed as dev dependencies as well.

httptools, uvicorn[standard], psycopg2-binary, gunicorn are not production depedencies.
This are "runtime" dependencies that are picked up by the application but not explicitly depended upon.
These should either be re-installed using poetry's dependency groups functionality or installed only during the build process.
