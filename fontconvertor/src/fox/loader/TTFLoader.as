package fox.loader
{
	import com.codeazur.as3swf.tags.TagDefineFont2;

	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;
	import flash.net.URLStream;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;

	import fox.FontEvent;
	import fox.SwfBuilder;
	import fox.shape.TTF2FFT;

	import org.sepy.fontreader.TFont;
	import org.sepy.fontreader.TFontCollection;

	[Event(name="fontReady", type="fox.FontEvent")]
	[Event(name="complete", type="flash.events.Event")]
	[Event(name="securityError", type="flash.events.SecurityErrorEvent")]
	[Event(name="ioError", type="flash.events.IOErrorEvent")]
	[Event(name="error", type="flash.events.ErrorEvent")]
	public class TTFLoader extends EventDispatcher
	{
		private static var lastFontCount:int;

		private var _timer:Number=0;
		public function get timer():Number
		{
			return _timer;
		}

		private var req:URLRequest;

		public function load(req:URLRequest):void
		{
			this.req=req;
			var ins:URLStream=new URLStream();
			ins.addEventListener(Event.COMPLETE, onURLStreamEvent);
			ins.addEventListener(IOErrorEvent.IO_ERROR, onURLStreamEvent);
			ins.addEventListener(ProgressEvent.PROGRESS, onURLStreamProgress);
			ins.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onURLStreamEvent);
			ins.load(req);
		}

		protected function onURLStreamProgress(event:ProgressEvent):void
		{
			this.dispatchEvent(event);
		}

		private function onURLStreamEvent(event:Event):void
		{
			_timer=new Date().getTime();
			var ins:URLStream=URLStream(event.target);
			ins.removeEventListener(Event.COMPLETE, onURLStreamEvent);
			ins.removeEventListener(IOErrorEvent.IO_ERROR, onURLStreamEvent);
			ins.removeEventListener(ProgressEvent.PROGRESS, onURLStreamEvent);
			ins.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onURLStreamEvent);
			if (Event.COMPLETE == event.type)
			{
				setTimeout(encodeFont, 200, ins, req.url);
			}
			this.dispatchEvent(event);
		}

		private function encodeFont(ins:URLStream, url:String):void
		{
			try
			{
				var fontCollection:TFontCollection=TFontCollection.create(ins, req.url);
				var fonts:Array=[];
				var counts:int=fontCollection.getFontCount();
				for (var i:int=0; i < counts; i++)
				{
					var tfont:TFont=fontCollection.getFont(i);
					var fongtag:TagDefineFont2=TTF2FFT.convert(tfont);
					fonts.push(fongtag);
				}

				if (fonts.length == 0)
				{
					return;
				}

				var builder:SwfBuilder=new SwfBuilder();
				var swf:ByteArray=builder.buildFontSwf(fonts);
				var loader:Loader=new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
				var context:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain);
				context.allowCodeImport = true;
				loader.loadBytes(swf, context);
			}

			catch (e:Error)
			{
				trace(e.getStackTrace());
				this.dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, "The font can not be recognised"));
			}
		}

		private function onLoaderComplete(event:Event):void
		{
			var loaderInfo:LoaderInfo=LoaderInfo(event.target);
			loaderInfo.removeEventListener(Event.COMPLETE, onLoaderComplete);
			var evt:FontEvent=new FontEvent(FontEvent.FONT_READY);
			// var i:int=lastFontCount;
			// while (true)
			// {
			// 	var name:String=i.toString();
			// 	while (name.length < 3)
			// 	{
			// 		name="0" + name;
			// 	}
			// 	name=SwfBuilder.FONT_CLASS_NAME_PREFIX + name;
			// 	i++;
			// 	try
			// 	{
			// 		var clz:Class=loaderInfo.applicationDomain.getDefinition(name) as Class;
			// 		evt.fonts.push(clz);
			// 	}
			// 	catch (e:Error)
			// 	{
			// 		break;
			// 	}
			// }
			trace(lastFontCount, SwfBuilder.fontCount);
			for (var i:int = lastFontCount + 1; i <= SwfBuilder.fontCount; i++)
			{
				var name:String=i.toString();
				while (name.length < 3)
				{
					name="0" + name;
				}
				name=SwfBuilder.FONT_CLASS_NAME_PREFIX + name;
				try
				{
					trace("checking font", name);
					var clz:Class=loaderInfo.applicationDomain.getDefinition(name) as Class;
					evt.fonts.push(clz);
				}
				catch (e:Error)
				{
				}
			}
			lastFontCount = SwfBuilder.fontCount;
			_timer=new Date().getTime() - _timer;
			this.dispatchEvent(evt);
		}

	}
}
