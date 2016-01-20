/*----------------------------------------------------------------------------*/
/*                                                                            */
/* Copyright © 2015 FenHongXiang                                              */
/* 深圳粉红象科技有限公司                                                                										  */
/* www.fenhongxiang.com                                                       */
/* All rights reserved.                                                       */
/*                                                                            */
/*----------------------------------------------------------------------------*/

package upload
{
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import mx.controls.Alert;

	final public class JavaImageUploader extends ImageUploader
	{
		static private const SERVERLET_URL:String="http://localhost:80/UploadServer/UploadImageData";

		static private var _urlLoader:URLLoader;

		override public function upload(data:BitmapData):void
		{
			super.upload(data, onDataEncoded);
		}
		
		private function onDataEncoded(data:String):void
		{
			var request:URLRequest=new URLRequest(SERVERLET_URL);
				request.method=URLRequestMethod.POST;
			
			var _urlData:URLVariables = new URLVariables();
				_urlData.bitmap_data = data;
			
			request.data=_urlData;
			_urlLoader=new URLLoader()
			_urlLoader.addEventListener(Event.COMPLETE, function uploadComplete(e:Event):void
			{
				Alert.show(e.target.data.toString());
			});
			_urlLoader.addEventListener(IOErrorEvent.IO_ERROR, function errorHandler(e:IOErrorEvent):void
			{
				Alert.show(e.text);
			});
			
			_urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function errorHandler(e:SecurityErrorEvent):void
			{
				Alert.show(e.text);
			});
			
			_urlLoader.load(request);
		}

		public function JavaImageUploader()
		{
		}
	}
}
