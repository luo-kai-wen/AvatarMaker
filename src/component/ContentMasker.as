/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Copyright © 2015 FenHongXiang                                              */
/* 深圳粉红象科技有限公司                                                                										  */
/* www.fenhongxiang.com                                                       */
/* All rights reserved.                                                       */
/*                                                                            */
/*----------------------------------------------------------------------------*/
package component
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import mx.core.UIComponent;

	/**
	 * 图片外面的遮罩层
	 * 主要作用就是 控制剪切区域的大小和位置
	 * 该组件的大小和加载图片的容器大小一样
	 * */
	public class ContentMasker extends UIComponent
	{
		public function ContentMasker()
		{
			super();
		}

		internal var _cropInfoText:TextField=null;
		internal var _gridShape:Bitmap=null;
		internal var borderColor:uint=0xFF2ECC71; //0xFF56B8FF
		internal var borderWeight:uint=2;
		internal var maskAlpha:Number=0x3C;
		internal var maskColor:uint=0x8CE7FFFF;
		private var _cropGap:Number=60;
		private var _cropHeight:Number=64;
		private var _cropWidth:Number=64;
		private var cropzSizeDirty:Boolean=true;

		public function set cropHeight(value:Number):void
		{
			if (_cropHeight != value)
			{
				_cropHeight=value;
				adjustSize();

				cropzSizeDirty=true;
				invalidateDisplayList();
			}
		}

		public function set cropWidth(value:Number):void
		{
			if (_cropWidth != value)
			{
				_cropWidth=value;
				adjustSize();

				cropzSizeDirty=true;
				invalidateDisplayList();
			}
		}

		public function getCropRect():Rectangle
		{
			return new Rectangle((this.width - _cropWidth) >> 1, (this.height - _cropHeight) >> 1, _cropWidth, _cropHeight);
		}

		override protected function createChildren():void
		{
			super.createChildren();

			_gridShape=new Bitmap();
			_gridShape.x=0;
			_gridShape.y=0;

			_cropInfoText=new TextField();
			_cropInfoText.text=_cropWidth + " x " + _cropHeight;
			_cropInfoText.height=20;
			_cropInfoText.borderColor=0x2ECC71;
			_cropInfoText.width=60;
			_cropInfoText.textColor=0xFFFFFF;
			_cropInfoText.background=true;
			_cropInfoText.backgroundColor=0x2ECC71;
			_cropInfoText.selectable=false;
			_cropInfoText.mouseEnabled=false;

			this.addChild(_gridShape);
			this.addChild(_cropInfoText);
		}

		override protected function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w, h);

			if (cropzSizeDirty)
			{
				redrawGrid();
				_cropInfoText.text=_cropWidth + " x " + _cropHeight;
				_cropInfoText.x=int(this.width / 2 + _cropWidth / 2 + borderWeight);
				_cropInfoText.y=int(this.height / 2 - _cropHeight / 2 - borderWeight);
				cropzSizeDirty=false;
			}
		}

		internal function redrawGrid():void
		{
			var cropStartPt:Point=new Point(int((this.width - _cropWidth) >> 1), int((this.height - _cropHeight) >> 1));

			if (_gridShape != null)
			{
				var maskData:BitmapData=new BitmapData(this.width, this.height);

				var cropRect:Rectangle=new Rectangle(cropStartPt.x, cropStartPt.y, _cropWidth, _cropHeight);
				var maskRect:Rectangle=new Rectangle(0, 0, this.width, this.height);
				var borderRect:Rectangle=new Rectangle(cropRect.x - borderWeight, cropRect.y - borderWeight, cropRect.width + 2 * borderWeight, cropRect.height + 2 * borderWeight);

				maskData.fillRect(maskRect, maskColor);
				maskData.fillRect(borderRect, borderColor);
				maskData.fillRect(cropRect, 0x00FFFFFF);

				_gridShape.bitmapData=null;
				_gridShape.bitmapData=maskData;
			}
		}

		private function adjustSize():void
		{
			var hGap:int=this.width - _cropWidth;
			var vGap:int=this.height - _cropHeight;

			if (vGap < _cropGap)
			{
				this.height+=_cropGap;
			}

			if (hGap < _cropGap)
			{
				this.width+=_cropGap;
			}
		}
	}
}
