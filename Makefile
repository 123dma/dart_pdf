 # Copyright (C) 2017, David PHAM-VAN <dev.nfet.net@gmail.com>
 #
 # Licensed under the Apache License, Version 2.0 (the "License");
 # you may not use this file except in compliance with the License.
 # You may obtain a copy of the License at
 #
 #     http://www.apache.org/licenses/LICENSE-2.0
 #
 # Unless required by applicable law or agreed to in writing, software
 # distributed under the License is distributed on an "AS IS" BASIS,
 # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 # See the License for the specific language governing permissions and
 # limitations under the License.

 DART_SRC=$(shell find . -name '*.dart')
 CLNG_SRC=$(shell find printing/ios -name '*.java' -o -name '*.m' -o -name '*.h') $(shell find printing/android -name '*.java' -o -name '*.m' -o -name '*.h')
 SWFT_SRC=$(shell find . -name '*.swift')
 FONTS=pdf/open-sans.ttf pdf/open-sans-bold.ttf pdf/roboto.ttf pdf/noto-sans.ttf pdf/genyomintw.ttf
 COV_PORT=9292

all: $(FONTS) format

pdf/open-sans.ttf:
	curl -L "https://github.com/google/fonts/raw/master/apache/opensans/OpenSans-Regular.ttf" > $@

pdf/open-sans-bold.ttf:
	curl -L "https://github.com/google/fonts/raw/master/apache/opensans/OpenSans-Bold.ttf" > $@

pdf/roboto.ttf:
	curl -L "https://github.com/google/fonts/raw/master/apache/robotomono/RobotoMono-Regular.ttf" > $@

pdf/noto-sans.ttf:
	curl -L "https://raw.githubusercontent.com/google/fonts/master/ofl/notosans/NotoSans-Regular.ttf" > $@

pdf/genyomintw.ttf:
	curl -L "https://github.com/ButTaiwan/genyo-font/raw/master/TW/GenYoMinTW-Heavy.ttf" > $@

format: format-dart format-clang format-swift

format-dart: $(DART_SRC)
	dartfmt -w --fix $^

format-clang: $(CLNG_SRC)
	clang-format -style=Chromium -i $^

format-swift: $(SWFT_SRC)
	swiftformat --swiftversion 4.2 $^

.coverage:
	pub global activate coverage
	touch $@

node_modules:
	npm install lcov-summary

test: $(FONTS) .coverage node_modules
	cd pdf; pub get
	cd pdf; pub global run coverage:collect_coverage --port=$(COV_PORT) -o coverage.json --resume-isolates --wait-paused &\
	dart --enable-asserts --disable-service-auth-codes --enable-vm-service=$(COV_PORT) --pause-isolates-on-exit test/all_tests.dart
	cd pdf; pub global run coverage:format_coverage --packages=.packages -i coverage.json --report-on lib --lcov --out lcov.info
	cd pdf; for EXAMPLE in $(shell cd pdf; find example -name '*.dart'); do dart $$EXAMPLE; done
	cd printing/example; flutter packages get
	cd printing/example; flutter test
	node_modules/.bin/lcov-summary pdf/lcov.info

clean:
	git clean -fdx -e .vscode

publish-pdf: format clean
	find pdf -name pubspec.yaml -exec sed -i -e 's/^dependency_overrides:/_dependency_overrides:/g' '{}' ';'
	cd pdf; pub publish -f
	find pdf -name pubspec.yaml -exec sed -i -e 's/^_dependency_overrides:/dependency_overrides:/g' '{}' ';'

publish-printing: format clean
	find printing -name pubspec.yaml -exec sed -i -e 's/^dependency_overrides:/_dependency_overrides:/g' '{}' ';'
	cd printing; pub publish -f
	find printing -name pubspec.yaml -exec sed -i -e 's/^_dependency_overrides:/dependency_overrides:/g' '{}' ';'

.pana:
	pub global activate pana
	touch $@

analyze: .pana
	@find pdf -name pubspec.yaml -exec sed -i -e 's/^dependency_overrides:/_dependency_overrides:/g' '{}' ';'
	@find printing -name pubspec.yaml -exec sed -i -e 's/^dependency_overrides:/_dependency_overrides:/g' '{}' ';'
	@pub global run pana --no-warning --source path pdf 2> /dev/null | python pana_report.py
	@pub global run pana --no-warning --source path printing 2> /dev/null | python pana_report.py
	@find pdf -name pubspec.yaml -exec sed -i -e 's/^_dependency_overrides:/dependency_overrides:/g' '{}' ';'
	@find printing -name pubspec.yaml -exec sed -i -e 's/^_dependency_overrides:/dependency_overrides:/g' '{}' ';'

.dartfix:
	pub global activate dartfix
	touch $@

fix: .dartfix
	cd pdf; pub get
	cd pdf; pub global run dartfix:fix --overwrite .
	cd printing; flutter packages get
	cd printing; pub global run dartfix:fix --overwrite .

.PHONY: test format format-dart format-clang clean publish-pdf publish-printing analyze
