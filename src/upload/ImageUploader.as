package upload
{
	import flash.display.BitmapData;
	import flash.events.ProgressEvent;
	import flash.external.ExternalInterface;

	CONFIG::LOGGING
	{
		import mx.controls.Alert;
	}

	/**
	 *
	 * @author www.fenhongxiang.com
	 *
	 * */
	public final class ImageUploader
	{
		public function ImageUploader()
		{
		}

		private var _callBackFunction:Function;

		/**
		 * 图片上传成功，服务器返回地址的时候调用的回调函数
		 *
		 * */
		public function set callBackFunction(value:Function):void
		{
			_callBackFunction = value;
		}

		private var _onProgress:Function;

		/**
		 * 图片编码进度函数
		 *
		 * */
		public function set onProgress(value:Function):void
		{
			_onProgress = value;
		}

		/**
		 * @param data 包含图像信息的BitmapData对象
		 * @param callBack 结果回调函数
		 *
		 * */
		public function upload(data:BitmapData, callBack:Function):void
		{
			_callBackFunction = callBack;

			if (data != null)
			{
				//使用异步解码器
				var asyncEncoder:JPEGAsyncEncoder = new JPEGAsyncEncoder(100);//编码质量默认100，可根据需要自行修改
					asyncEncoder.addEventListener(ProgressEvent.PROGRESS, onProgressHandler);
					asyncEncoder.addEventListener(JPEGAsyncCompleteEvent.JPEGASYNC_COMPLETE, asyncComplete);
					asyncEncoder.encode(data);
			}
			else
			{
				if (_callBackFunction != null)
				{
					_callBackFunction("");//传入无效的BitmapData对象，结果返回空
				}
			}
		}

		private function onProgressHandler(e:ProgressEvent):void
		{
			if (_onProgress != null)
			{
				_onProgress(e.bytesLoaded / e.bytesTotal);
			}
		}

		private function asyncComplete(e:JPEGAsyncCompleteEvent):void
		{
			var imgBase64Encoder:Base64Encoder = new Base64Encoder();
				imgBase64Encoder.encodeBytes(e.ImageData);
			
			var result:String = imgBase64Encoder.toString();

			//把Base64字符串直接返回给网页端
			if (ExternalInterface.available)
			{
				try
				{
					ExternalInterface.call('setAvatarData', result);
				}
				catch (e:*)
				{
					CONFIG::LOGGING
					{
						Alert.show("JS接口调用失败", "错误");
					}
				}
				finally
				{
					if (_callBackFunction != null)
					{
						_callBackFunction(result);
					}
				}
			}
			else
			{
				CONFIG::LOGGING
				{
					Alert.show("外部接口不可用", "错误");
				}
			}
		}
	}
}
