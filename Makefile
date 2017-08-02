.PHONY: core-requirements update-pip-requirements requirements \
	syntax-check clean-tox tox \
	bump-major bump-minor bump-patch

core-requirements:
	pip install "pip>=9,<9.1" setuptools "pip-tools>=1"

update-pip-requirements: core-requirements
	pip install -U "pip>=9,<9.1" setuptools "pip-tools>=1"
	pip-compile -U requirements.in

requirements: core-requirements
	pip-sync requirements.txt

syntax-check: requirements
	ansible-playbook -i tests/inventory tests/example.yml --syntax-check

clean-tox:
	rm -rf .tox

tox: requirements
	tox

bump-major:
	bumpversion major

bump-minor:
	bumpversion minor

bump-patch:
	bumpversion patch
