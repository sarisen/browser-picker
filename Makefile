SCHEME      = BrowserPicker
PROJECT     = BrowserPicker.xcodeproj
BUILD_DIR   = .build
DERIVED     = $(BUILD_DIR)/DerivedData
APP_PATH    = /Applications/BrowserPicker.app

.PHONY: build test clean open install run logs logs-follow logs-clear

build:
	xcodebuild \
	  -project $(PROJECT) \
	  -scheme $(SCHEME) \
	  -configuration Debug \
	  -derivedDataPath $(DERIVED) \
	  build

test:
	xcodebuild \
	  -project $(PROJECT) \
	  -scheme $(SCHEME) \
	  -configuration Debug \
	  -derivedDataPath $(DERIVED) \
	  -destination 'platform=macOS' \
	  test

install: build
	cp -R "$(DERIVED)/Build/Products/Debug/BrowserPicker.app" "$(APP_PATH)"
	@echo "Installed to $(APP_PATH)"

run:
	open "$(APP_PATH)"

all: install run

clean:
	rm -rf $(BUILD_DIR)
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean 2>/dev/null || true

open:
	open $(PROJECT)

archive:
	xcodebuild \
	  -project $(PROJECT) \
	  -scheme $(SCHEME) \
	  -configuration Release \
	  -derivedDataPath $(DERIVED) \
	  -archivePath $(BUILD_DIR)/BrowserPicker.xcarchive \
	  archive

logs:
	@cat ~/.config/browserpicker/browserpicker.log 2>/dev/null || echo "(no log file yet)"

logs-follow:
	tail -f ~/.config/browserpicker/browserpicker.log

logs-clear:
	rm -f ~/.config/browserpicker/browserpicker.log

config:
	@open ~/.config/browserpicker/ 2>/dev/null || \
	  (mkdir -p ~/.config/browserpicker && open ~/.config/browserpicker/)
