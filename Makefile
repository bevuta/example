PWD=$(shell pwd)

CHICKEN_PATH             = ../android-chicken
include $(CHICKEN_PATH)/config.mk

CHICKEN_HOST_PATH        = $(CHICKEN_PATH)/build/host
CHICKEN_TARGET_PATH      = $(CHICKEN_PATH)/build/target/data/data/$(PACKAGE_NAME)
CHICKEN_TARGET_EGGS_PATH = $(CHICKEN_TARGET_PATH)/lib/chicken/7

export PATH := $(SDK_PATH)/platform-tools:$(SDK_PATH)/tools:$(PATH)
export PATH := $(SDK_PATH)/tools:$(PATH)
export PATH := $(NDK_PATH):$(PATH)
export PATH := $(CHICKEN_PATH)/toolchain/$(PLATFORM)/bin:$(CHICKEN_HOST_PATH)/bin:$(PATH)
export PATH := /usr/lib/ccache:$(PATH)


all: run

run: install
	cd $(NAME); ant debug install
	adb shell am start -n $(PACKAGE_NAME)/.$(ACTIVITY)

run*: install
	adb shell killall $(PACKAGE_NAME)
	adb shell am start -n $(PACKAGE_NAME)/.$(ACTIVITY)

install: $(PWD)/$(NAME)/ $(PWD)/$(NAME)/libs/$(ARCH) $(PWD)/$(NAME)/libs/$(ARCH)/libchicken.so \
		$(foreach egg-path,$(shell ls $(CHICKEN_TARGET_EGGS_PATH)/*.so), \
			$(PWD)/$(NAME)/libs/$(ARCH)/lib$(shell basename $(egg-path))) \
		$(foreach scm-path,$(shell ls $(PWD)/scm/*.scm), \
			$(PWD)/$(NAME)/libs/$(ARCH)/lib$(shell basename $(scm-path) .scm).so)

$(PWD)/$(NAME)/libs/$(ARCH)/libchicken.so: $(CHICKEN_TARGET_PATH)/lib/libchicken.so
	cp $(CHICKEN_TARGET_PATH)/lib/libchicken.so $(PWD)/$(NAME)/libs/$(ARCH)/libchicken.so

$(PWD)/$(NAME)/libs/$(ARCH)/lib%.so: $(CHICKEN_TARGET_EGGS_PATH)/%.so
	cp $< $@

$(PWD)/$(NAME)/libs/$(ARCH)/lib%.so: $(PWD)/scm/%.scm
	ant -f  $(PACKAGE_NAME)/build.xml debug
	android-csc -s -llog -landroid -I$(PWD)/scm/include -o $@ $<

$(PWD)/$(NAME)/libs/$(ARCH):
	mkdir -p $@

clean:
	rm -rf $(NAME)
