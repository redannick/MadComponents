/**
 * <p>Original Author: Daniel Freeman</p>
 *
 * <p>Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:</p>
 *
 * <p>The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.</p>
 *
 * <p>THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.</p>
 *
 * <p>Licensed under The MIT License</p>
 * <p>Redistributions of files must retain the above copyright notice.</p>
 */

package com.danielfreeman.madcomponents {
	
	import flash.display.Shape;
	import flash.text.TextFormat;
	import flash.geom.PerspectiveProjection;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.Loader;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getDefinitionByName;
/**
 *  Image placeholder
 * <pre>
 * &lt;image
 *    id = "IDENTIFIER"
 *    alignH = "left|right|centre|fill"
 *    alignV = "top|bottom|centre|fill"
 *    visible = "true|false"
 *    width = "NUMBER"
 *    height = "NUMBER"
 *    clickable = "true|false"
 *    scale = "true|false"
 *    border = "true|false|rounded"
 *    background = "#rrggbb"
 *    stretch = "true|false"
 * /&gt;
 * </pre>
 */
	public class UIPickerView extends MadSprite implements IComponentUI {
		
		public static const CHANGE:String = "change";
		
		protected static const SHOWN:int = 3;
		protected static const SHOWN_ALT:int = 4;
		protected static const LABEL_GAP:Number = 32.0;
		protected static const HEIGHT:Number = 150.0;
		protected static const HEIGHT_ALT:Number = 200.0;
		
		protected static const SLOW_DECAY:Number = 0.90;
		protected static const FAST_DECAY:Number = 0.99;
		protected static const SLOW_DECAY_DELTA:Number = 0.40;
		protected static const FAST_DECAY_DELTA:Number = 100;
		protected static const DELTA_THRESHOLD:Number = 5.0;
		protected static const FLICK_THRESHOLD:Number = 2;
		protected static const NO_SWIPE_THRESHOLD:int = 1;
		protected static const BOUNCE_DELTA:Number = 8.0;
		protected static const CURSOR_HEIGHT:Number = 36.0;
		
		protected static const SMOOTH:Number = 0.5;
		protected static const DAMPEN:Number = 0.3;
		
		protected static const TEXT_FORMAT:TextFormat = new TextFormat("Arial", 18, 0x99999F);
		protected static const TEXT_FORMAT_CURSOR:TextFormat = new TextFormat("Arial", 20, 0x000000);
		
		protected static const BACKGROUND:uint = 0xF3F3F9;
		protected static const CURSOR_COLOUR:uint = 0xF3F3F9;
		protected static const LINE_COLOUR:uint = 0x999999;
		protected static const ADJUSTMENT:Number = 1.0;
		protected static const OFFSET:Number = 1.01;

		protected var _labels:Vector.<Vector.<UILabel>>;
		protected var _cursorLabels:Vector.<Vector.<UILabel>>;
		protected var _labelLayer:Sprite;
		protected var _cursorLayer:Sprite;
		protected var _positions:Vector.<Number>;
		protected var _moving:Vector.<Boolean>;
		protected var _group:int = 0;
		protected var _index:int = 0;
		protected var _groupWidths:Vector.<Number>;
		protected var _pickerWidth:Number = 0;
		protected var _deltas:Vector.<Number>;
		protected var _lastMouseY:Number;
		protected var _noSwipeCount:int;
		protected var _touch:Boolean = false;
		protected var _movement:Timer = new Timer(50);
		protected var _alt:Boolean;
		
		protected var _background:uint = BACKGROUND;
		protected var _cursorColour:uint = CURSOR_COLOUR;
		protected var _lineColour:uint = LINE_COLOUR;
		protected var _textFormat:TextFormat = TEXT_FORMAT;
		protected var _textFormatCursor:TextFormat = TEXT_FORMAT_CURSOR;
		
	
		public function UIPickerView(screen:Sprite, xml:XML, attributes:Attributes) {
			super(screen, attributes);
			_alt = xml.@alt == "true";
			if (xml.@background.length() > 0) {
				_background = UI.toColourValue(xml.@background);
			}
			if (xml.@cursorColour.length() > 0) {
				_cursorColour = UI.toColourValue(xml.@cursorColour);
			}
			if (xml.@lineColour.length() > 0) {
				_lineColour = UI.toColourValue(xml.@lineColour);
			}
			if (xml.@cursorTextColour.length() > 0) {
				_textFormatCursor.color = UI.toColourValue(xml.@cursorTextColour);
			}
			if (xml.@textColour.length() > 0) {
				_textFormat.color = UI.toColourValue(xml.@textColour);
			}
			addChild(_labelLayer = new Sprite());
			addChild(_cursorLayer = new Sprite());
			_cursorLayer.y = theHeight / 2;// - (_alt ? 7 : 4);
			_labelLayer.y = theHeight / 2 ;
			_labelLayer.transform.perspectiveProjection = new PerspectiveProjection();
			setSize();
			if (xml.data.length() > 0) {
				xmlData = xml.data[0];
			}
			addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			_movement.addEventListener(TimerEvent.TIMER, movement);
		}
		
		
		protected function initialiseCursor(columns:int):void {
			_cursorLayer.removeChildren();
			_cursorLabels = new Vector.<Vector.<UILabel>>();
			for (var i:int = 0; i < columns; i++) {
				var labelGroup:Vector.<UILabel> = new Vector.<UILabel>();
				labelGroup.push(new UILabel(_cursorLayer, 0, 0, "", TEXT_FORMAT_CURSOR));
				labelGroup.push(new UILabel(_cursorLayer, 0, 0, "", TEXT_FORMAT_CURSOR));
				_cursorLabels.push(labelGroup);
			}
		}
		
		
		protected function offset(value:Number):Number {
			return (value - _attributes.width / 2) * OFFSET + _attributes.width / 2;
		}
		
		
		protected function cursorLabels(group:int):void {
			var position:Number = _positions[group];
			var index:int = Math.round(position / LABEL_GAP);
			var firstLabel:UILabel = _cursorLabels[group][0];
			if (index >= 0 && index < _labels[group].length) {
				var firstSource:UILabel = _labels[group][index];
				var firstPoint:Point = _cursorLayer.globalToLocal(firstSource.local3DToGlobal(new Vector3D()));
				firstLabel.text = firstSource.text;
				firstLabel.x = offset(firstPoint.x);
				firstLabel.y = firstPoint.y;
				firstLabel.visible = true;
			}
			else {
				firstLabel.visible = false;
			}
			var secondIndex:int = (index * LABEL_GAP - position <= 0) ? index + 1 : index - 1;
			var secondLabel:UILabel = _cursorLabels[group][1];
			if (secondIndex >= 0 && secondIndex < _labels[group].length) {
				var secondSource:UILabel = _labels[group][secondIndex];
				var secondPoint:Point = _cursorLayer.globalToLocal(secondSource.local3DToGlobal(new Vector3D()));
				secondLabel.text = secondSource.text;
				secondLabel.x = offset(secondPoint.x);
				secondLabel.y = secondPoint.y;
				secondLabel.visible = true;
			}
			else {
				secondLabel.visible = false;
			}
		}
		
		
		protected function deltaToDecay(delta:Number):Number {
			var factor:Number;
			if (Math.abs(delta) < SLOW_DECAY_DELTA) {
				factor = 0.0;
			}
			else if (Math.abs(delta) > FAST_DECAY_DELTA) {
				factor = 1.0;
			}
			else {
				factor = (Math.abs(delta) - SLOW_DECAY_DELTA) / (FAST_DECAY_DELTA - SLOW_DECAY_DELTA);
			}
			return factor * (FAST_DECAY - SLOW_DECAY) + SLOW_DECAY;
		}
		
		
		protected function xToPicker(value:Number):int {
			var adjustedValue:Number = (value - _attributes.width / 2) * ADJUSTMENT + _attributes.width / 2;
			var position:Number = (_attributes.widthH - _pickerWidth) / 2;
			for (var i:int = 0; i < _groupWidths.length; i++) {
				position += _groupWidths[i] + _attributes.paddingH;
				if (adjustedValue < position) {
					return i;
				}
			}
			return _groupWidths.length - 1;
		}

		
		protected function mouseDown(event:MouseEvent):void {
			if (_positions) {
				_touch = true;
				_group = xToPicker(mouseX);
				_noSwipeCount = 0;
				_lastMouseY = mouseY;
				stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
				stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			}
		}
		
		
		protected function maximumPosition(group:int):Number {
			return LABEL_GAP * (_labels[group].length - 1);
		}
		
		
		protected function outsideSlideRange(position:Number, group:int):Boolean {
			return position < 0 || position > maximumPosition(group);
		}
		
		
		protected function snapCondition(position:Number, delta:Number):Boolean {
			return  (delta <= DELTA_THRESHOLD && Math.abs(LABEL_GAP * Math.round(position / LABEL_GAP) - position) <= DELTA_THRESHOLD);
		}
		
		
		protected function snapPosition(position:Number):Number {
			return LABEL_GAP * Math.round(position / LABEL_GAP);
		}
		
		
		protected function mouseMove(event:MouseEvent):void {
			var delta:Number = -_positions[_group];
			_positions[_group] -= (outsideSlideRange(_positions[_group], _group) ? DAMPEN : 1.0) * (mouseY - _lastMouseY);
			delta += _positions[_group];
			
			arrangePickerGroup(_positions[_group], _group);
			
			if (Math.abs(delta) > DELTA_THRESHOLD) {
				if (delta * _deltas[_group] > 0) {
					_deltas[_group] = SMOOTH * _deltas[_group] + (1 - SMOOTH) * delta;
				}
				else {
					_deltas[_group] = delta;
				}
				_noSwipeCount = 0;
			}
			else if (++_noSwipeCount > NO_SWIPE_THRESHOLD) {
				_deltas[_group] = 0;
			}
			_lastMouseY = mouseY;
			_moving[_group] = true;	
		}
		
		
		protected function mouseUp(event:MouseEvent):void {
			_touch = false;
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
			if (!_movement.running) {
				_movement.reset();
				_movement.start();
			}
		}
		
		
		protected function movement(event:Event):void {
			var moving:Boolean = false;
			for (var i:int = 0; i < _positions.length; i++) if (_moving[i]) {
				var delta:Number = _deltas[i];
				if (!_touch || i != _group) {
					var position:Number = _positions[i];
					if (outsideSlideRange(position, i)) {
						var target:Number = (position < 0) ? 0 : maximumPosition(i); 
						if (Math.abs(target - position) < DELTA_THRESHOLD) {
							position = target;
							_moving[i] = false;
						}
						else {
							position += (target - position) / 2;
							moving = true;
						}
						delta = 0;					
					}
					else if (Math.abs(delta) > DELTA_THRESHOLD) {
						delta *= deltaToDecay(delta);
						moving = true;
					}
					else {
						position = snapPosition(position);
						delta = 0;
						_moving[i] = false;
					}
					arrangePickerGroup(position += delta, i);
					_deltas[i] = delta;
					_positions[i] = position;
				}
			}
			if (!moving) {
				_movement.stop();
				dispatchEvent(new Event(CHANGE));
			}
		}
		
/**
 *  Set XML data
 */
		public function set xmlData(value:XML):void {
			var result:Vector.<Vector.<String>> = new Vector.<Vector.<String>>();
			for each (var group:XML in value.children()) {
				var row:Vector.<String> = new Vector.<String>();
				for each (var item:XML in group.children()) {
					if (item.@label.length() > 0) {
						row.push(item.@label);
					}
					else {
						row.push(item.localName().toString());
					}
				}
			result.push(row);
			}
			data = result;
		}
		
				
		public function set data(value:Vector.<Vector.<String>>):void {
			clear();
			_groupWidths = new Vector.<Number>();
			_pickerWidth = (value.length - 1) * _attributes.paddingH;
			for each (var valueGroup:Vector.<String> in value) {
				var labelGroup:Vector.<UILabel> = new Vector.<UILabel>();
				var maximumWidth:Number = 0;
				for each (var valueString:String in valueGroup) {
					var label:UILabel = new UILabel(_labelLayer, 0, 0, valueString, TEXT_FORMAT);
					labelGroup.push(label);
					maximumWidth = Math.max(maximumWidth, label.width);
				}
				_labels.push(labelGroup);
				_groupWidths.push(maximumWidth);
				_pickerWidth += maximumWidth;
			}
			_deltas = new Vector.<Number>(value.length, true);
			_positions = new Vector.<Number>(value.length, true);
			_moving = new Vector.<Boolean>(value.length, true);
			initialiseCursor(value.length);
			for (var i:int = 0; i < value.length; i++) {
				_deltas[i] = 0.0;
				_positions[i] = 0.0;
				_moving[i] = false;
				arrangePickerGroup(0, i);
			}
		}
		
		
		public function clear():void {
			_labelLayer.removeChildren();
			_labels = new Vector.<Vector.<UILabel>>();
		}
		
		
		protected function arrangePickerGroup(position:Number, group:int):void {
			var labelGroup:Vector.<UILabel> = _labels[group];
			var index:int = Math.round(position / LABEL_GAP);
			var xPosition:Number = (_attributes.width - _pickerWidth) / 2;
			for (var j:int = 0; j < group; j++) {
				xPosition += _groupWidths[j] + _attributes.paddingH;
			}
			var i:int = 0;
			var shown:int = (_alt ? SHOWN_ALT : SHOWN);
			for each (var label:UILabel in labelGroup) {
				if (i > index - shown && i < index + shown) {
					label.visible = true;
					var labelHeight:Number = label.height;
					var yPosition:Number = i * LABEL_GAP - position;
					var theta:Number = yPosition / (LABEL_GAP * 3 * (shown + 1)) * Math.PI;
					var angle:Number = 180 * theta / Math.PI;
					yPosition = (LABEL_GAP * shown) * Math.sin(Math.PI / 3 * yPosition / (LABEL_GAP * shown));
					if (yPosition < 0) {
						yPosition *= 1.08;
					}
					var zPosition:Number = (LABEL_GAP * shown) * (1 - Math.cos(1.5 * theta));
					label.transform.matrix3D = new Matrix3D();
					label.transform.matrix3D.appendTranslation(0, - labelHeight / 2, 0);
					label.transform.matrix3D.appendRotation(angle, Vector3D.X_AXIS);
					label.transform.matrix3D.appendTranslation(xPosition, yPosition , zPosition);
					label.alpha = Math.cos(2.0 * theta);
				}
				else {
					label.visible = false;
				}
				i++;
			}
			cursorLabels(group);
		}
		
		
		protected function setSize():void {
			graphics.clear();
			graphics.beginFill(_background);
			graphics.drawRect(-UI.PADDING, 0, _attributes.width + 2 * UI.PADDING, theHeight);
			graphics.endFill();
			_labelLayer.transform.perspectiveProjection.projectionCenter = new Point(_attributes.width / 2, 0); 
			_cursorLayer.graphics.clear();
			_cursorLayer.graphics.beginFill(_cursorColour);
			_cursorLayer.graphics.drawRect(-UI.PADDING, -CURSOR_HEIGHT / 2, _attributes.width + 2 * UI.PADDING, CURSOR_HEIGHT);
			_cursorLayer.graphics.beginFill(_lineColour);
			_cursorLayer.graphics.drawRect(-UI.PADDING, -CURSOR_HEIGHT / 2, _attributes.width + 2 * UI.PADDING, 1);
			_cursorLayer.graphics.drawRect(-UI.PADDING, CURSOR_HEIGHT / 2 - 1, _attributes.width + 2 * UI.PADDING, 1);
			var mask:Shape = _cursorLayer.mask ? Shape(_cursorLayer.mask) : new Shape();
			mask.graphics.clear();
			mask.graphics.beginFill(0);
			mask.graphics.drawRect(-UI.PADDING, -CURSOR_HEIGHT / 2, _attributes.width + 2 * UI.PADDING, CURSOR_HEIGHT);
			_cursorLayer.addChild(_cursorLayer.mask = mask);
		}
		
		
		override public function layout(attributes:Attributes):void {
			super.layout(attributes);
			setSize();
			if (_positions) {
				for (var i:int = 0; i < _positions.length; i++) {
					arrangePickerGroup(_positions[i], i);
					_moving[i] = true;
				}
				if (!_movement.running) {
					_movement.reset();
					_movement.start();
				}
			}
		}
		
		
		override public function get theHeight():Number {
			return _alt ? HEIGHT_ALT : HEIGHT;
		}
		
		
		public function get indices():Vector.<int> {
			var result:Vector.<int> = new Vector.<int>();
			for each (var position:Number in _positions) {
				result.push(Math.round(position / LABEL_GAP));
			}
			return result;
		}
		
		
		public function set indices(value:Vector.<int>):void {
			_positions = new Vector.<Number>();
			var group:int = 0;
			for each (var position:Number in value) {
				_positions.push(position * LABEL_GAP);
				arrangePickerGroup(position * LABEL_GAP, group++);
			}
		}
		
		public function get movementTimer():Timer {return _movement;}
		
		
		override public function destructor():void {
			removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			_movement.removeEventListener(TimerEvent.TIMER, movement);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
		}

	}
}
