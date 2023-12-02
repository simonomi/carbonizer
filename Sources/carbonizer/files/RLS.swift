//
//  RLS.swift
//
//
//  Created by alice on 2023-11-25.
//

import BinaryParser

struct RLS: Codable {
	var kasekis: [Kaseki?]
	
	struct Kaseki: Codable, Equatable {
		var _label: String?
		
		var isEntry: Bool
		var unknown1: Bool
		var unbreakable: Bool
		var destroyable: Bool
		
		var unknown2: UInt8
		var unknown3: UInt8
		var unknown4: UInt8
		var unknown5: UInt8
		
		var fossilImage: UInt32
		var rockImage: UInt32
		var fossilConfig: UInt32
		var rockConfig: UInt32
		var buyPrice: UInt32
		var sellPrice: UInt32
		
		var unknown6: UInt32
		var unknown7: UInt32
		var fossilName: UInt32
		var unknown8: UInt32
		
		var time: UInt32
		var passingScore: UInt32
		
		var unknown9: UInt32
		var unknown10: UInt32
		var unknown11: UInt32
		
		var unknown12: UInt32?
		var unknown13: UInt32?
	}
	
	@BinaryConvertible
	struct Binary {
		var magicBytes = "RLS"
		var kasekiCount: UInt32
		var offsetsStart: UInt32 = 0xC
		@Offset(givenBy: \Self.offsetsStart)
		@Count(givenBy: \Self.kasekiCount)
		var offsets: [UInt32]
		@Offsets(givenBy: \Self.offsets)
		var kasekis: [Kaseki]
		
		@BinaryConvertible
		struct Kaseki {
			var isEntry: UInt8
			var unknown1: UInt8
			var unbreakable: UInt8
			var destroyable: UInt8
			
			var unknown2: UInt8 // only high for special vivos
			var unknown3: UInt8 // only 0 for droppings and some specials
			var unknown4: UInt8 = 0
			var unknown5: UInt8 = 0
			
			var fossilImage: UInt32
			var rockImage: UInt32
			var fossilConfig: UInt32 // can be negative ?
			var rockConfig: UInt32
			var buyPrice: UInt32
			var sellPrice: UInt32
			
			var unknown6: UInt32 // 100 for jewels, 0 else
			var unknown7: UInt32 // 1 for jewels, 2 for droppings, 0 else
			var fossilName: UInt32 // jewels/droppings only
			var unknown8: UInt32 = 0
			
			var time: UInt32
			var passingScore: UInt32
			
			var unknown9: UInt32 // same as unknown2
			var unknown10: UInt32 // isEntry but 2 instead of 1...??????
			var unknown11: UInt32 = 68 // 68 is length up to here...?
			
			@If(\Self.isEntry, is: .equalTo(1))
			var unknown12: UInt32? // 1638, 2048, 2458
								   // difference: 410
			@If(\Self.isEntry, is: .equalTo(1))
			var unknown13: UInt32? // 2048, 2867
								   // difference: 819
								   // only 2867 for goyle
		}
	}
}

// MARK: packed
extension RLS: FileData {
	init(packed: Binary) {
		kasekis = packed.kasekis.enumerated().map(Kaseki.init)
	}
}

extension RLS.Kaseki {
	init?(index: Int, _ kaseki: RLS.Binary.Kaseki) {
		_label = kasekiLabels[index]
		
		isEntry = kaseki.isEntry > 0
		guard isEntry else { return nil }
		unknown1 = kaseki.unknown1 > 0
		unbreakable = kaseki.unbreakable > 0
		destroyable = kaseki.destroyable > 0
		
		unknown2 = kaseki.unknown2
		unknown3 = kaseki.unknown3
		unknown4 = kaseki.unknown4
		unknown5 = kaseki.unknown5
		
		fossilImage = kaseki.fossilImage
		rockImage = kaseki.rockImage
		fossilConfig = kaseki.fossilConfig
		rockConfig = kaseki.rockConfig
		buyPrice = kaseki.buyPrice
		sellPrice = kaseki.sellPrice
		
		unknown6 = kaseki.unknown6
		unknown7 = kaseki.unknown7
		fossilName = kaseki.fossilName
		unknown8 = kaseki.unknown8
		
		time = kaseki.time
		passingScore = kaseki.passingScore
		
		unknown9 = kaseki.unknown9
		unknown10 = kaseki.unknown10
		unknown11 = kaseki.unknown11
		
		unknown12 = kaseki.unknown12
		unknown13 = kaseki.unknown13
	}
}

extension RLS.Binary: InitFrom {
	init(_ rls: RLS) {
		kasekiCount = UInt32(rls.kasekis.count)
		
		offsets = createOffsets(
			start: offsetsStart + kasekiCount * 4,
			sizes: rls.kasekis.map(\.size)
		)
		
		kasekis = rls.kasekis.map(Kaseki.init)
	}
}

extension RLS.Kaseki? {
	var size: UInt32 {
		if self == nil {
			68
		} else {
			76
		}
	}
}

fileprivate let kasekiLabels = [
	1: "T-Rex Head",
	2: "T-Rex Body",
	3: "T-Rex Arms",
	4: "T-Rex Legs",
	5: "Daspleto Head",
	6: "Daspleto Body",
	7: "Daspleto Arms",
	8: "Daspleto Legs",
	9: "Gorgo Head",
	10: "Gorgo Body",
	11: "Gorgo Arms",
	12: "Gorgo Legs",
	13: "Tarbo Head",
	14: "Tarbo Body",
	15: "Tarbo Arms",
	16: "Tarbo Legs",
	17: "Alio Head",
	18: "Alio Body",
	19: "Alio Arms",
	20: "Alio Legs",
	21: "Siamo Head",
	22: "Siamo Body",
	23: "Siamo Arms",
	24: "Siamo Legs",
	25: "Alectro Head",
	26: "Alectro Body",
	27: "Alectro Arms",
	28: "Alectro Legs",
	29: "Guan Head",
	30: "Guan Body",
	31: "Guan Arms",
	32: "Guan Legs",
	33: "Shanshan Head",
	34: "Shanshan Body",
	35: "Shanshan Arms",
	36: "Shanshan Legs",
	37: "Allo Head",
	38: "Allo Body",
	39: "Allo Arms",
	40: "Allo Legs",
	41: "Metria Head",
	42: "Metria Body",
	43: "Metria Arms",
	44: "Metria Legs",
	45: "Megalo Head",
	46: "Megalo Body",
	47: "Megalo Arms",
	48: "Megalo Legs",
	49: "Venator Head",
	50: "Venator Body",
	51: "Venator Arms",
	52: "Venator Legs",
	53: "S-Raptor Head",
	54: "S-Raptor Body",
	55: "S-Raptor Arms",
	56: "S-Raptor Legs",
	57: "Giganto Head",
	58: "Giganto Body",
	59: "Giganto Arms",
	60: "Giganto Legs",
	61: "Cryo Head",
	62: "Cryo Body",
	63: "Cryo Arms",
	64: "Cryo Legs",
	65: "Carchar Head",
	66: "Carchar Body",
	67: "Carchar Arms",
	68: "Carchar Legs",
	69: "Acro Head",
	70: "Acro Body",
	71: "Acro Arms",
	72: "Acro Legs",
	73: "F-Raptor Head",
	74: "F-Raptor Body",
	75: "F-Raptor Arms",
	76: "F-Raptor Legs",
	77: "Spinax Head",
	78: "Spinax Body",
	79: "Spinax Arms",
	80: "Spinax Legs",
	81: "Neo Head",
	82: "Neo Body",
	83: "Neo Arms",
	84: "Neo Legs",
	85: "Compso Head",
	86: "Compso Body",
	87: "Compso Arms",
	88: "Compso Legs",
	89: "Sopteryx Head",
	90: "Sopteryx Body",
	91: "Sopteryx Arms",
	92: "Sopteryx Legs",
	93: "Delta Head",
	94: "Delta Body",
	95: "Delta Arms",
	96: "Delta Legs",
	97: "Tro Head",
	98: "Tro Body",
	99: "Tro Arms",
	100: "Tro Legs",
	101: "Nychus Head",
	102: "Nychus Body",
	103: "Nychus Arms",
	104: "Nychus Legs",
	105: "M-Raptor Head",
	106: "M-Raptor Body",
	107: "M-Raptor Arms",
	108: "M-Raptor Legs",
	109: "U-Raptor Head",
	110: "U-Raptor Body",
	111: "U-Raptor Arms",
	112: "U-Raptor Legs",
	113: "V-Raptor Head",
	114: "V-Raptor Body",
	115: "V-Raptor Arms",
	116: "V-Raptor Legs",
	117: "Breme Head",
	118: "Breme Body",
	119: "Breme Arms",
	120: "Breme Legs",
	121: "Aopteryx Head",
	122: "Aopteryx Body",
	123: "Aopteryx Arms",
	124: "Aopteryx Legs",
	125: "Coelo Head",
	126: "Coelo Body",
	127: "Coelo Arms",
	128: "Coelo Legs",
	129: "Dilopho Head",
	130: "Dilopho Body",
	131: "Dilopho Arms",
	132: "Dilopho Legs",
	133: "Spino Head",
	134: "Spino Body",
	135: "Spino Arms",
	136: "Spino Legs",
	137: "Angato Head",
	138: "Angato Body",
	139: "Angato Arms",
	140: "Angato Legs",
	141: "Sucho Head",
	142: "Sucho Body",
	143: "Sucho Arms",
	144: "Sucho Legs",
	145: "Onyx Head",
	146: "Onyx Body",
	147: "Onyx Arms",
	148: "Onyx Legs",
	149: "Cerato Head",
	150: "Cerato Body",
	151: "Cerato Arms",
	152: "Cerato Legs",
	153: "Carno Head",
	154: "Carno Body",
	155: "Carno Arms",
	156: "Carno Legs",
	157: "Orno Head",
	158: "Orno Body",
	159: "Orno Arms",
	160: "Orno Legs",
	161: "Cheirus Head",
	162: "Cheirus Body",
	163: "Cheirus Arms",
	164: "Cheirus Legs",
	165: "O-Raptor Head",
	166: "O-Raptor Body",
	167: "O-Raptor Arms",
	168: "O-Raptor Legs",
	169: "Zino Head",
	170: "Zino Body",
	171: "Zino Arms",
	172: "Zino Legs",
	173: "Brachio Head",
	174: "Brachio Body",
	175: "Brachio Arms",
	176: "Brachio Legs",
	177: "Salto Head",
	178: "Salto Body",
	179: "Salto Arms",
	180: "Salto Legs",
	181: "Shuno Head",
	182: "Shuno Body",
	183: "Shuno Arms",
	184: "Shuno Legs",
	185: "Perso Head",
	186: "Perso Body",
	187: "Perso Arms",
	188: "Perso Legs",
	189: "Seismo Head",
	190: "Seismo Body",
	191: "Seismo Arms",
	192: "Seismo Legs",
	193: "Apato Head",
	194: "Apato Body",
	195: "Apato Arms",
	196: "Apato Legs",
	197: "Amargo Head",
	198: "Amargo Body",
	199: "Amargo Arms",
	200: "Amargo Legs",
	201: "Stego Head",
	202: "Stego Body",
	203: "Stego Arms",
	204: "Stego Legs",
	205: "Yango Head",
	206: "Yango Body",
	207: "Yango Arms",
	208: "Yango Legs",
	209: "Jiango Head",
	210: "Jiango Body",
	211: "Jiango Arms",
	212: "Jiango Legs",
	213: "Kentro Head",
	214: "Kentro Body",
	215: "Kentro Arms",
	216: "Kentro Legs",
	217: "Lexo Head",
	218: "Lexo Body",
	219: "Lexo Arms",
	220: "Lexo Legs",
	221: "Nodo Head",
	222: "Nodo Body",
	223: "Nodo Arms",
	224: "Nodo Legs",
	225: "Ankylo Head",
	226: "Ankylo Body",
	227: "Ankylo Arms",
	228: "Ankylo Legs",
	229: "Saichan Head",
	230: "Saichan Body",
	231: "Saichan Arms",
	232: "Saichan Legs",
	233: "Goyle Head",
	234: "Goyle Body",
	235: "Goyle Arms",
	236: "Goyle Legs",
	237: "Pelto Head",
	238: "Pelto Body",
	239: "Pelto Arms",
	240: "Pelto Legs",
	241: "Hypsi Head",
	242: "Hypsi Body",
	243: "Hypsi Arms",
	244: "Hypsi Legs",
	245: "Nasaur Head",
	246: "Nasaur Body",
	247: "Nasaur Arms",
	248: "Nasaur Legs",
	249: "Igua Head",
	250: "Igua Body",
	251: "Igua Arms",
	252: "Igua Legs",
	253: "Ourano Head",
	254: "Ourano Body",
	255: "Ourano Arms",
	256: "Ourano Legs",
	257: "Lambeo Head",
	258: "Lambeo Body",
	259: "Lambeo Arms",
	260: "Lambeo Legs",
	261: "Maia Head",
	262: "Maia Body",
	263: "Maia Arms",
	264: "Maia Legs",
	265: "Anato Head",
	266: "Anato Body",
	267: "Anato Arms",
	268: "Anato Legs",
	269: "Paraloph Head",
	270: "Paraloph Body",
	271: "Paraloph Arms",
	272: "Paraloph Legs",
	273: "Pachy Head",
	274: "Pachy Body",
	275: "Pachy Arms",
	276: "Pachy Legs",
	277: "Stygi Head",
	278: "Stygi Body",
	279: "Stygi Arms",
	280: "Stygi Legs",
	281: "Goyo Head",
	282: "Goyo Body",
	283: "Goyo Arms",
	284: "Goyo Legs",
	285: "Proto Head",
	286: "Proto Body",
	287: "Proto Arms",
	288: "Proto Legs",
	289: "Tricera Head",
	290: "Tricera Body",
	291: "Tricera Arms",
	292: "Tricera Legs",
	293: "Styraco Head",
	294: "Styraco Body",
	295: "Styraco Arms",
	296: "Styraco Legs",
	297: "Einio Head",
	298: "Einio Body",
	299: "Einio Arms",
	300: "Einio Legs",
	301: "Centro Head",
	302: "Centro Body",
	303: "Centro Arms",
	304: "Centro Legs",
	305: "Penta Head",
	306: "Penta Body",
	307: "Penta Arms",
	308: "Penta Legs",
	309: "Pachrino Head",
	310: "Pachrino Body",
	311: "Pachrino Arms",
	312: "Pachrino Legs",
	313: "Mihu Head",
	314: "Mihu Body",
	315: "Mihu Arms",
	316: "Mihu Legs",
	317: "Ptera Head",
	318: "Ptera Body",
	319: "Ptera Arms",
	320: "Ptera Legs",
	321: "Coatlus Head",
	322: "Coatlus Body",
	323: "Coatlus Arms",
	324: "Coatlus Legs",
	325: "Jara Head",
	326: "Jara Body",
	327: "Jara Arms",
	328: "Jara Legs",
	329: "Dimorph Head",
	330: "Dimorph Body",
	331: "Dimorph Arms",
	332: "Dimorph Legs",
	333: "Guera Head",
	334: "Guera Body",
	335: "Guera Arms",
	336: "Guera Legs",
	337: "Krona Head",
	338: "Krona Body",
	339: "Krona Arms",
	340: "Krona Legs",
	341: "Futabi Head",
	342: "Futabi Body",
	343: "Futabi Arms",
	344: "Futabi Legs",
	345: "Elasmo Head",
	346: "Elasmo Body",
	347: "Elasmo Arms",
	348: "Elasmo Legs",
	349: "Plesio Head",
	350: "Plesio Body",
	351: "Plesio Arms",
	352: "Plesio Legs",
	353: "Shoni Head",
	354: "Shoni Body",
	355: "Shoni Arms",
	356: "Shoni Legs",
	357: "Arsith Head",
	358: "Arsith Body",
	359: "Arsith Arms",
	360: "Arsith Legs",
	361: "Brontoth Head",
	362: "Brontoth Body",
	363: "Brontoth Arms",
	364: "Brontoth Legs",
	365: "Elasmoth Head",
	366: "Elasmoth Body",
	367: "Elasmoth Arms",
	368: "Elasmoth Legs",
	369: "Hoplo Head",
	370: "Hoplo Body",
	371: "Hoplo Arms",
	372: "Hoplo Legs",
	373: "Andrarch Head",
	374: "Andrarch Body",
	375: "Andrarch Arms",
	376: "Andrarch Legs",
	377: "Paki Head",
	378: "Paki Body",
	379: "Paki Arms",
	380: "Paki Legs",
	381: "Smilo Head",
	382: "Smilo Body",
	383: "Smilo Arms",
	384: "Smilo Legs",
	385: "Mammoth Head",
	386: "Mammoth Body",
	387: "Mammoth Arms",
	388: "Mammoth Legs",
	389: "Tryma Head",
	390: "Tryma Body",
	391: "Tryma Arms",
	392: "Tryma Legs",
	393: "Megath Head",
	394: "Megath Body",
	395: "Megath Arms",
	396: "Megath Legs",
	397: "Chelon Head",
	398: "Chelon Body",
	399: "Chelon Arms",
	400: "Chelon Legs",
	401: "Dinomaton",
	405: "Duna",
	409: "Raptin",
	413: "Dynal",
	417: "Frigi",
	421: "Igno",
	425: "Squik",
	429: "Squirk",
	433: "Squirth",
	437: "Squilk",
	441: "Squiro",
	445: "Guhweep",
	449: "Guhvorn",
	453: "Guhlith",
	457: "OP Frigi",
	461: "OP Igno",
	501: "Small Pearl",
	502: "Small Pearl",
	503: "Small Pearl",
	504: "Emerald",
	505: "Emerald",
	506: "Emerald",
	507: "Diamond",
	508: "Diamond",
	509: "Diamond",
	510: "Double Pearl",
	511: "Double Pearl",
	512: "Double Pearl",
	513: "Sapphire",
	514: "Sapphire",
	515: "Sapphire",
	516: "Double Diamond",
	517: "Double Diamond",
	518: "Double Diamond",
	519: "Giant Pearl",
	520: "Giant Pearl",
	521: "Giant Pearl",
	522: "Ruby",
	523: "Ruby",
	524: "Ruby",
	525: "Quad Diamond",
	526: "Quad Diamond",
	527: "Quad Diamond",
	528: "Colossal Diamond",
	529: "Colossal Diamond",
	530: "Colossal Diamond",
	601: "Large Dropping Fossil",
	602: "Large Dropping Fossil",
	603: "Large Dropping Fossil",
	604: "Large Double Dropping Fossil",
	605: "Large Double Dropping Fossil",
	606: "Large Double Dropping Fossil",
	607: "Small Dropping Fossil - center",
	608: "Small Dropping Fossil - center",
	609: "Small Dropping Fossil - center",
	610: "Small Dropping Fossil - bottom right",
	611: "Small Dropping Fossil - bottom right",
	612: "Small Dropping Fossil - bottom right",
	613: "Small Dropping Fossil - top right",
	614: "Small Dropping Fossil - top right",
	615: "Small Dropping Fossil - top right",
	616: "Small Dropping Fossil - center bottom",
	617: "Small Dropping Fossil - center bottom",
	618: "Small Dropping Fossil - center bottom",
	619: "Small Dropping Fossil - center top",
	620: "Small Dropping Fossil - center top",
	621: "Small Dropping Fossil - center top",
	622: "Triple Dropping Fossil - down up down",
	623: "Triple Dropping Fossil - down up down",
	624: "Triple Dropping Fossil - down up down",
	625: "Triple Dropping Fossil - diagonal line",
	626: "Triple Dropping Fossil - diagonal line",
	627: "Triple Dropping Fossil - diagonal line",
	628: "Small Double Dropping Fossil",
	629: "Small Double Dropping Fossil",
	630: "Small Double Dropping Fossil"
]
