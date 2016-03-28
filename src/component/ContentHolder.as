//------------------------------------------------------------------------------
//
//   Copyright 2016 www.fenhongxiang.com 
//   All rights reserved. 
//   By :ljh 
//
//------------------------------------------------------------------------------

package component
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.containers.Canvas;
	import mx.controls.Image;
	import mx.core.UIComponent;
	import mx.effects.Move;
	import mx.effects.Resize;
	import mx.events.EffectEvent;
	import mx.events.FlexEvent;
	import mx.graphics.ImageSnapshot;
	import mx.managers.CursorManager;
	
	public class ContentHolder extends Canvas
	{
		public function ContentHolder()
		{
			super();
			init();
		}

		public var contentMasker:ContentMasker = null;
		public var maintainAspectRatio:Boolean = true;
		internal var _content:Sprite = null;
		[Embed(source="assets/bkFill.jpg")]
		private var ImgField:Class;
		private var _contentDiffPt:Point = null;
		private var _contentSnapShort:UIComponent = null;
		private var _imageScale:Number = 1.0;
		private var _originContentSize:Point = new Point(0, 0); //缓存原始图像的宽度和高度
		private var _originImageData:BitmapData = null;
		private var backgroundDirty:Boolean = true;
		private var contentPosPt:Point = new Point();
		[Embed(source="assets/grabCursor.png")]
		private var grabCursor:Class;
		private var moveEft:Move = new Move();
		private var scaleEft:Resize = new Resize();

		public function centerContent(force:Boolean=false):void
		{
			if (_content != null && !moveEft.isPlaying)
			{
				var cropRect:Rectangle = contentMasker.getCropRect();
				var contectRect:Rectangle = new Rectangle(_content.x, _content.y, _content.width, _content.height);

				if (!contectRect.containsRect(cropRect))
				{
					moveEft.duration	 = 350;
					moveEft.xFrom		 = _content.x;
					moveEft.xTo			 = int(cropRect.x - (contectRect.width - cropRect.width) / 2);
					moveEft.yFrom		 = _content.y;
					moveEft.yTo			 = int(cropRect.y - (contectRect.height - cropRect.height) / 2);
					moveEft.play([_content]);
				}
			}
		}

		public function get content():Sprite
		{
			return _content;
		}

		public function set content(value:Sprite):void
		{
			if (value != _content)
			{
				removeOldContentObject();

				_content=value;

				if (_content != null)
				{
					_content.addEventListener(MouseEvent.MOUSE_DOWN, onContentMouseDownHandler, false, 0, true);

					if (_content is Image)
					{
						_content.addEventListener(FlexEvent.DATA_CHANGE, onImgeDataLoadedHandler, false, 0, true);
						_content.addEventListener(Event.COMPLETE, onImgeDataLoadedHandler, false, 0, true);
					}
					else
					{
						_content.addEventListener(FlexEvent.CREATION_COMPLETE, onContentLoadedHandler, false, 0, true);
					}

					this.addChild(_content);
				}
			}
		}

		public function getCropData():BitmapData
		{
			var sourceBD:BitmapData = ImageSnapshot.captureBitmapData(this);
			var cropBD:BitmapData = null
			if (contentMasker != null && content)
			{
				var contentRect:Rectangle = new Rectangle(content.x, content.y, content.width, content.height);
				var cropRect:Rectangle = contentMasker.getCropRect().intersection(contentRect);

				if (cropRect.width <= 0 || cropRect.height <= 0)
					return null;

				cropBD = new BitmapData(cropRect.width, cropRect.height, false, 0xFFFFFFFF);

				cropBD.copyPixels(sourceBD, cropRect, new Point(0, 0));
			}

			return cropBD;
		}

		override public function set height(value:Number):void
		{
			super.height = value;
			backgroundDirty = true;
		}

		public function scaleContent(scaleFactor:Number=0):void
		{
			_imageScale += scaleFactor;

			if (_content && !scaleEft.isPlaying)
			{
				//scaleFactor = getValidScaleValue(scaleFactor);

				var newWidth:Number = Math.round(_originContentSize.x * _imageScale);
				var newHeight:Number = 0;

				if (maintainAspectRatio)
				{
					newHeight = newWidth / (_originContentSize.x / _originContentSize.y);
				}
				else
				{
					newHeight = Math.round(_originContentSize.y * _imageScale);
				}
				
				//在 AIR 1.5 和 Flash Player 10 中，BitmapData 对象的最大宽度或高度为 8,191 像素，并且像素总数不能超过 16,777,215 像素。
				//（因此，如果 BitmapData 对象的宽度为 8,191 像素，则其高度只能为 2,048 像素。）在 Flash Player 9 及早期版本和 AIR 1.1 及早期版本中，
				//高度最大为 2,880 像素，宽度最大为 2,880 像素。如果指定的宽度值或高度值大于 2880，则不会创建新实例。
				if (newHeight <= 0 || newWidth <= 0 || newHeight * newWidth >= 16777215)
				{
					return;
				}

				//如果缩放的对象为Image，则对Image中的BitmapData数据进行缩放，开启位图的平滑处理
				if (_content is Image && _originImageData != null)
				{
					try
					{
						var scaleBitmapData:BitmapData = new BitmapData(newWidth, newHeight);
					}
					catch (e:ArgumentError) // 宽度和/或高度超过最大尺寸
					{
						return;
					}

					var scaleMatrix:Matrix = new Matrix();
					scaleMatrix.scale(_imageScale, newHeight / _originContentSize.y);

					try
					{
						scaleBitmapData.draw(_originImageData, scaleMatrix, null, null, null, true);
					}
					catch (e:*)
					{
						return;
					}
					
					Image(_content).source = new Bitmap(scaleBitmapData);
				}

				scaleEft.duration	= 450;
				scaleEft.heightFrom = _content.height;
				scaleEft.heightTo	= newHeight;
				scaleEft.widthFrom	= _content.width;
				scaleEft.widthTo	= newWidth;
				scaleEft.addEventListener(EffectEvent.EFFECT_END, onScaledEndHandler);
				scaleEft.play([_content]);
			}
		}

		override public function set width(value:Number):void
		{
			super.width = value;
			backgroundDirty = true;
		}

		protected function drawBackgroundGrid():void
		{
			var field:BitmapData = new ImgField().bitmapData;
			
			this.graphics.clear();
			this.graphics.beginBitmapFill(field, null, true, false);
			this.graphics.drawRect(0, 0, width, height);
			this.graphics.endFill();
			
			backgroundDirty = false;
		}

		override protected function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w, h);

			if (backgroundDirty)
			{
				drawBackgroundGrid();
			}
		}

		private function createContentSnapShort():void
		{
			if (_content != null)
			{
				var contectBD:BitmapData = ImageSnapshot.captureBitmapData(_content);

				_contentSnapShort = new UIComponent();
				
				_contentSnapShort.width			= contectBD.width;
				_contentSnapShort.height		= contectBD.height;
				_contentSnapShort.mouseChildren	= false;
				_contentSnapShort.graphics.beginBitmapFill(contectBD);
				_contentSnapShort.graphics.drawRect(0, 0, contectBD.width, contectBD.height);
				_contentSnapShort.graphics.endFill();

				this.addChild(_contentSnapShort);
			}
		}

		private function getValidScaleValue(scale:Number):Number
		{
			var cropRect:Rectangle = contentMasker.getCropRect();
			var minContentScaleFator:Number = 0;

			minContentScaleFator = Math.min(cropRect.width / _originContentSize.x, cropRect.height / _originContentSize.y);

			return Math.max(minContentScaleFator, scale);
		}

		private function init():void
		{
			this.verticalScrollPolicy = "off";
			this.horizontalScrollPolicy = "off";
			this.mouseEnabled = false;
			this.addEventListener(FlexEvent.CREATION_COMPLETE, onHolderCreatedHandler, false, 0, true);
		}

		//---------------------------------------------------------
		// 3. Content MouseUp
		//---------------------------------------------------------
		private function onContenMouseUpHandler(e:MouseEvent):void
		{
			if (_content && _contentSnapShort)
			{
				_contentSnapShort.removeEventListener(MouseEvent.MOUSE_MOVE, onContentMouseMoveHandler);

				_content.x = _contentSnapShort.x;
				_content.y = _contentSnapShort.y;

				this.removeChild(_contentSnapShort);
				_contentSnapShort = null;

				_content.visible = true;

				CursorManager.removeAllCursors();
			}
		}

		private function onContentLoadedHandler(e:FlexEvent):void
		{
			_originContentSize = new Point(_content.width, _content.height);
			_content.removeEventListener(FlexEvent.CREATION_COMPLETE, onContentLoadedHandler);

			_content.x = int((this.width - _content.width) >> 1);
			_content.y = int((this.height - _content.height) >> 1);
		}

		private function onContentMouseDownHandler(e:MouseEvent):void
		{
			if (_content != null)
			{
				_contentDiffPt=new Point(_content.x - this.mouseX, _content.y - this.mouseY);

				// 创建Content的快照，隐藏Content本身
				createContentSnapShort();
				
				if (_contentSnapShort != null)
				{
					_contentSnapShort.x = _content.x;
					_contentSnapShort.y = _content.y;
					_contentSnapShort.addEventListener(MouseEvent.MOUSE_MOVE, onContentMouseMoveHandler, false, 0, true);
					_contentSnapShort.addEventListener(MouseEvent.MOUSE_OUT, onContentMouseOutHandler, false, 0, true);
					_content.visible = false;
				}

				CursorManager.setCursor(grabCursor, 2, -16, -8);
			}
		}

		//---------------------------------------------------------
		// 2. Content MouseMove
		//---------------------------------------------------------
		private function onContentMouseMoveHandler(e:MouseEvent):void
		{
			var newX:int = this.mouseX + _contentDiffPt.x;
			var newY:int = this.mouseY + _contentDiffPt.y;

			var cropRect:Rectangle = contentMasker.getCropRect();

			var dH:Number = e.currentTarget.width - cropRect.width;
			var dV:Number = e.currentTarget.height - cropRect.height;

			dH = dH < 0 ? cropRect.width : dH;
			dV = dV < 0 ? cropRect.height : dV;

			var moveableRect:Rectangle = new Rectangle(cropRect.topLeft.x - dH, cropRect.topLeft.y - dV, dH, dV);

			if (moveableRect.contains(newX, newY))
			{
				e.currentTarget.x = newX;
				e.currentTarget.y = newY;
			}

			e.updateAfterEvent();
		}

		private function onContentMouseOutHandler(e:MouseEvent):void
		{
			onContenMouseUpHandler(e);
		}

		//-----------------------------------------------------------------------------------------------
		//

		// event handlers
		//

		//-----------------------------------------------------------------------------------------------
		private function onHolderCreatedHandler(e:FlexEvent):void
		{
			this.systemManager.addEventListener(MouseEvent.MOUSE_UP, onContenMouseUpHandler, false, 0, true);
		}

		private function onImgeDataLoadedHandler(e:Event):void
		{
			//BMP图像读data属性
			var bmpMap:Bitmap = (_content as Image).data as Bitmap;
			var bmpWidth:Number = 0.0;
			var bmpHeight:Number = 0.0;

			if (bmpMap != null)
			{
				bmpWidth = bmpMap.bitmapData.width;
				bmpHeight = bmpMap.bitmapData.height;

				_originContentSize = new Point(bmpWidth, bmpHeight);//缓存原始图像的尺寸
				_originImageData = bmpMap.bitmapData;
			}
			else
			{
				_originContentSize = new Point((_content as Image).contentWidth, (_content as Image).contentHeight);
				_originImageData = Bitmap((_content as Image).content).bitmapData;
			}

			_content.x = 0;
			_content.y = 0;

			if (_contentSnapShort)
			{
				_contentSnapShort.graphics.clear();
			}
			
			_imageScale = 1.0;

			var scale:Number=1 - Math.min(this.width / _originContentSize.x, 1);

			scaleContent(-scale);
			centerContent(true);
		}

		private function onScaledEndHandler(e:EffectEvent):void
		{
			centerContent();
		}

		private function removeOldContentObject():void
		{
			if (_content)
			{
				if (this.contains(_content))
				{
					this.removeChild(_content);
					_content=null;
				}
			}
		}
	}
}