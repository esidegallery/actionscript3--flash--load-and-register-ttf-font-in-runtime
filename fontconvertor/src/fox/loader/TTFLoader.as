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

	import fox.FontEvent;
	import fox.SwfBuilder;
	import fox.shape.TTF2FFT;

	import org.sepy.fontreader.TFontCollection;

	[Event(name="fontReady", type="fox.FontEvent")]
	[Event(name="complete", type="flash.events.Event")]
	[Event(name="securityError", type="flash.events.SecurityErrorEvent")]
	[Event(name="ioError", type="flash.events.IOErrorEvent")]
	[Event(name="error", type="flash.events.ErrorEvent")]
	public class TTFLoader extends EventDispatcher
	{
		private var req:URLRequest;
		private var builder:SwfBuilder;

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
			var ins:URLStream=URLStream(event.target);
			ins.removeEventListener(Event.COMPLETE, onURLStreamEvent);
			ins.removeEventListener(IOErrorEvent.IO_ERROR, onURLStreamEvent);
			ins.removeEventListener(ProgressEvent.PROGRESS, onURLStreamEvent);
			ins.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onURLStreamEvent);
			if (event.type == Event.COMPLETE)
			{
				encodeFont(ins, req.url);
			}
			this.dispatchEvent(event);
		}

		private function encodeFont(ins:URLStream, url:String):void
		{
			try
			{
				var fontCollection:TFontCollection=TFontCollection.create(ins, req.url);
				if (fontCollection.getFontCount() == 0)
				{
					return;
				}

				builder=new SwfBuilder();
				var fontTag:TagDefineFont2 = TTF2FFT.convert(fontCollection.getFont(0));
				var swf:ByteArray=builder.buildFontSwf(fontTag);
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
			try
			{
				var clz:Class=loaderInfo.applicationDomain.getDefinition(builder.lastFontClassName) as Class;
				evt.fonts.push(clz);
			}
			catch (e:Error)
			{
			}
			this.dispatchEvent(evt);
		}
	}
}
