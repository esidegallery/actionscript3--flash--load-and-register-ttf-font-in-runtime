package fox
{
	import by.blooddy.crypto.CRC32;

	import com.codeazur.as3swf.SWF;
	import com.codeazur.as3swf.SWFData;
	import com.codeazur.as3swf.data.SWFSymbol;
	import com.codeazur.as3swf.tags.TagDefineFont2;
	import com.codeazur.as3swf.tags.TagDoABC;
	import com.codeazur.as3swf.tags.TagEnd;
	import com.codeazur.as3swf.tags.TagFileAttributes;
	import com.codeazur.as3swf.tags.TagFrameLabel;
	import com.codeazur.as3swf.tags.TagShowFrame;
	import com.codeazur.as3swf.tags.TagSymbolClass;
	import com.codeazur.as3swf.timeline.Frame;
	import com.esidegallery.utils.MathUtils;

	import flash.utils.ByteArray;

	public class SwfBuilder
	{
		private static const CLASS_NAME_LENGTH:uint = 7;
		private static const MAGIC_BYTE_HEX:String='10002e0000000011074c4955484f4e470039493a5c70353433313635343132335c78685f70686f746f5c666f6e74636f6e766572746f72546573745c7372633b3b4c4955484f4e472e61730568656c6c6f3348692074686572652c206e69636520746f206d65657420796f752120476c616420796f752063616e2072656164206d65203a290f4c4955484f4e472f4c4955484f4e470a666c6173682e7465787404466f6e74064f626a6563741c5f5f676f5f746f5f63746f725f646566696e6974696f6e5f68656c700466696c6538493a5c70353433313635343132335c78685f70686f746f5c666f6e74636f6e766572746f72546573745c7372635c4c4955484f4e472e617303706f73023939175f5f676f5f746f5f646566696e6974696f6e5f68656c70023535050501160216071801000407020107030807020903000002000000060000000200020a020b0d0c0e0f020b0d0c10010102090400010000000102010144010002000103000101040503d030470000010102050619f103f007d030ef0104000af009d049002c05f00a85d5f00b470000020201010421d030f103f00565005d036603305d026602305d02660258001d1d6801f103f003470000';

		public var lastFontClassName:String;

		protected function hex2bytes(str:String):ByteArray
		{
			var ba:ByteArray=new ByteArray();
			var length:uint=str.length;
			for (var i:uint=0; i < length; i+=2)
			{
				var hexByte:String=str.substr(i, 2);
				var byte:uint=parseInt(hexByte, 16);
				ba.writeByte(byte);
			}
			ba.position=0;
			return ba;
		}

		protected function bytes2hex(bytes:ByteArray):String
		{
			var hexs:String="";
			while (bytes.bytesAvailable)
			{
				var hex:String=bytes.readUnsignedByte().toString(16);
				while (hex.length != 2)
				{
					hex="0" + hex;
				}
				hexs+=hex;
			}
			return hexs;
		}

		protected function string2hex(str:String):String
		{
			var ba:ByteArray=new ByteArray();
			ba.writeUTFBytes(str);
			ba.position=0;
			return bytes2hex(ba);
		}

		private function getMagicBytes(name:String):ByteArray
		{
			var magic:String=MAGIC_BYTE_HEX.replace(/4c4955484f4e47/g, string2hex(name));
			return hex2bytes(magic);
		}

		public function buildFontSwf(fontTag:TagDefineFont2):ByteArray
		{
			var swfTemp:SWF=new SWF();
			swfTemp.tags.push(new TagFileAttributes());

			var tagf:TagFrameLabel=new TagFrameLabel();
			swfTemp.tags.push(tagf);

			var tsc:TagSymbolClass=new TagSymbolClass();

			var f:Frame=new Frame();

			fontTag.characterId=1;
			var fontData:SWFData=new SWFData();
			fontTag.publish(fontData, 10);
			fontData.position=0;
			
			lastFontClassName=getClassName(fontTag);

			//abc
			var abc:TagDoABC=new TagDoABC();
			abc.lazyInitializeFlag=false;
			abc.bytes.writeBytes(getMagicBytes(lastFontClassName));
			swfTemp.tags.push(abc);

			//font
			swfTemp.tags.push(fontTag);

			//font to abc
			var sy:SWFSymbol=new SWFSymbol();
			sy.name=lastFontClassName;
			sy.tagId=1;
			tsc.symbols.push(sy);
			f.characters.push(1);

			swfTemp.tags.push(tsc);

			//show
			swfTemp.tags.push(new TagShowFrame());

			//end
			swfTemp.tags.push(new TagEnd());

			swfTemp.frames.push(f);

			//publish the generated SWF
			var swfdata:ByteArray=new ByteArray();
			swfTemp.publish(swfdata);

			return swfdata;
		}

		private static function getClassName(fontTag:TagDefineFont2):String
		{
			var fontName:String = fontTag.fontName;
			if (!fontName)
			{
				return "FONT001";
			}

			// Make a 7-character class name consisting of first character of fontName + CRC32 hash + filler if necessary:
			var name:String = fontName.charAt().replace(/[^a-z_$]/gi, "_");
			var hashSource:String = [
				fontTag.fontName,
				fontTag.bold ? 1 : 0,
				fontTag.italic ? 1 : 0
			].join("|");
			var ba:ByteArray = new ByteArray;
			ba.writeUTF(hashSource);
			name += MathUtils.toStringCustom(CRC32.hashBytes(ba), 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_$');
			if (name.length > CLASS_NAME_LENGTH)
			{
				name = name.substr(0, CLASS_NAME_LENGTH);
			}
			while (name.length < CLASS_NAME_LENGTH)
			{
				if (fontName.length > 1)
				{
					name += fontName.charAt(1).replace(/[^a-z0-9\$_-]/gi, "_");
				}
				else
				{
					name += name.charAt(0);
				}
			}
			return name;
		}
	}
}