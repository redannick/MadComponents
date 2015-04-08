﻿/** * <p>Original Author: Daniel Freeman</p> * * <p>Permission is hereby granted, free of charge, to any person obtaining a copy * of this software and associated documentation files (the "Software"), to deal * in the Software without restriction, including without limitation the rights * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell * copies of the Software, and to permit persons to whom the Software is * furnished to do so, subject to the following conditions:</p> * * <p>The above copyright notice and this permission notice shall be included in * all copies or substantial portions of the Software.</p> * * <p>THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN * THE SOFTWARE.</p> * * <p>Licensed under The MIT License</p> * <p>Redistributions of files must retain the above copyright notice.</p> */package com.danielfreeman.madcomponents {		import flash.display.Sprite;	import flash.events.Event;	import flash.events.FocusEvent;	import flash.events.KeyboardEvent;	import flash.events.TextEvent;	import flash.text.TextFieldAutoSize;	import flash.text.TextFieldType;	import flash.text.TextFormat;	import flash.ui.Keyboard;	/** * A Text Field where the background colour changes while focussed */		public class UIBlueText extends UILabel {				public static const ENTER:String = "enter";		public static var BLUE:uint=0xCCCCFF;		public static const GREY:uint=0x999999;				protected var ivmode:Boolean;		public var initial:Boolean;		protected var initialtext:String;		protected var maxwdth:int;	//	protected var backup:String;		protected var focussed:Boolean=false;		protected var savewdth:int=-1;		protected var _defaultColour:uint = uint.MAX_VALUE;		protected var _highlightColour:uint = BLUE;		protected var _initialTextColour:uint = GREY;		protected var _saveTextColour:uint;		protected var _password:Boolean = false;		protected var _screen:Sprite;		public function UIBlueText(screen:Sprite,xx:int,yy:int,txt:String=' ',wdth:int=-1,format:TextFormat=null,ivmode:Boolean=false,promptColour:uint = GREY) {			_screen = screen;			initialtext=txt;maxwdth=wdth;_initialTextColour=promptColour;			super(screen,xx,yy,txt,format);initial=this.ivmode=ivmode;							mouseEnabled=selectable=true;						type=TextFieldType.INPUT;						addEventListener(FocusEvent.FOCUS_IN,focusin);			addEventListener(FocusEvent.FOCUS_OUT,focusout);			addEventListener(KeyboardEvent.KEY_UP,keyup);			addEventListener(Event.CHANGE,txtchange0);			if (wdth>=0) {				addEventListener(TextEvent.TEXT_INPUT, txtchange);				//autoSize=TextFieldAutoSize.NONE;width=wdth				}		}						public function set password(value:Boolean):void {			_password = value;			displayAsPassword = initial ? false : _password;		}						public function get password():Boolean {			return _password;		}						public function keyup(ev:KeyboardEvent):void {		//	if (ev.keyCode==Keyboard.ESCAPE) {text=backup;setSelection(super.text.length,super.text.length);stage.focus=null;}		//	else			if (ev.keyCode==Keyboard.ENTER && !multiline) {				stage.focus=null;				_screen.dispatchEvent(new Event(ENTER));				}		}		public function set defaultext(value:String):void {			initialtext=value;			ivmode = true;			if (initial) {				setInitialText();			}		}						public function setInitialText():void {			if (!initial) {				_saveTextColour = uint(defaultTextFormat.color);			}			setTextColour(_initialTextColour);			super.text = initialtext;			displayAsPassword = false;			initial = true;		}						protected function setTextColour(value:uint):void {			var textFormat:TextFormat = defaultTextFormat;			textFormat.color = value;			defaultTextFormat = textFormat;		}						public function set defaultColour(value:uint):void {			backgroundColor = _defaultColour = value;			background=true;		}						public function get defaultColour():uint {			return _defaultColour;		}						override public function get text():String {			return initial ? "" : super.text;		}						override public function set text(value:String):void {			if (ivmode && value=="") {				setInitialText();			}			else {				setTextColour(_saveTextColour);				super.text = value;				displayAsPassword = _password;				initial = false;			}			savewdth=width;			txtchange();		}						override public function set fixwidth(value:Number):void {			super.width=value;			savewdth=value;			maxwdth=-1;			autoSize=TextFieldAutoSize.NONE;			removeEventListener(TextEvent.TEXT_INPUT,txtchange);		}						public function txtchange(ev:TextEvent=null):void {			autoSize = TextFieldAutoSize.LEFT;			if (maxwdth>=0 && width>maxwdth) super.width=maxwdth;			else super.width=fixwidth=savewdth;			autoSize = TextFieldAutoSize.NONE;		}						public function clear(text:String = ""):void {			super.text = text;		}						protected function txtchange0(ev:Event=null):void {			initial = false;			displayAsPassword = _password;		}						protected function focusin(ev:FocusEvent):void {			background= _highlightColour < 0x1000000 && (_defaultColour<0x1000000 || backgroundColor!=0);			backgroundColor=_highlightColour;			if (initial && ivmode) {				super.text='';				displayAsPassword = _password;				var textFormat:TextFormat = defaultTextFormat;				textFormat.color = _saveTextColour;				defaultTextFormat = textFormat;				if (savewdth>0) fixwidth=savewdth;			}		//	backup=text;			focussed=true;					//	setSelection(super.text.length,super.text.length);		}						public function focusout(ev:FocusEvent=null):void {			if (super.text=='' && ivmode) {				setInitialText();				if (savewdth>0) fixwidth=savewdth;			} else initial=false;			focussed=false;			background=_defaultColour < 0x1000000;			if (background) {				backgroundColor=_defaultColour;			}		}						public function set highlightColour(value:uint):void {			_highlightColour = value;		}						public function focus():void {			stage.focus = this;		}						public function destructor():void {			removeEventListener(FocusEvent.FOCUS_IN,focusin);			removeEventListener(FocusEvent.FOCUS_OUT,focusout);			removeEventListener(KeyboardEvent.KEY_UP,keyup);			removeEventListener(Event.CHANGE,txtchange0);				removeEventListener(TextEvent.TEXT_INPUT,txtchange);		}	}}