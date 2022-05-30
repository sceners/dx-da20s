unit DisAsm;

// Version 2.0
//
// Unit for Disassembling r4300i Code written by Hartec
// ====================================================
// 
// You may use this unit freely and build it into your
// programms aslong as you credit me.
//
// You are also free to mail me bug fixes, hints or other
// Information that could help to make this Disassembler
// better.
//
// V1.0 : First release of my sources, alot of stuff was 
//        Correct in here, but it was enough for the 
//        beginning.
// V2.0 : Added COP opcodes and correct register names
//        and fixed some minor stuff
//
// Contact me on IRC in #N64DEV or drop me a mail at :
//
//               Hartec@dextrose.com                 
//
// (c) Hartec

interface

uses
  Windows, SysUtils;

Const

// ===========================================================================
//  Opcode Definitionen
// ===========================================================================

      //  40 Load and Store
      //  50 Branch
      // 100 Opcodes

      Opcode : array[0..63] of String =
       ('special','regimm ','j      ','jal    ','beq    ','bne    ','blez   ','bgtz   ',
        'addi   ','addiu  ','slti   ','sltiu  ','andi   ','ori    ','xori   ','lui    ',
        'cop0   ','cop1   ','cop2   ',#0       ,'beql   ','bnel   ','blezl  ','bgtzl  ',
        'daddi  ','daddiu ','ldl    ','ldr    ',#0       ,#0       ,#0       ,#0       ,
        'lb     ','lh     ','lwl    ','lw     ','lbu    ','lhu    ','lwr    ','lwu    ',
        'sb     ','sh     ','swl    ','sw     ','sdl    ','sdr    ','swr    ','cache  ',
        'll     ','lwc1   ','lwc2   ',#0       ,'lld    ','ldc1   ','ldc2   ','ld     ',
        'sc     ','swc1   ','swc2   ',#0       ,'scd    ','sdc1   ','sdc2   ','sd     ');

      Opcode_Mode : array[0..63] of shortint =
      (100,101,  2,  2, 50, 50, 51, 51,
         5,  4,  4,  4,  4,  4,  4, 10,
       102,103,104, -1, 50, 50, 51, 51,
         5,  4, 40, 40, -1, -1, -1, -1,
        40, 40, 40, 40, 40, 40, 40, 40,
        40, 40, 40, 40, 40, 40, 40,105,
        40, 40, 40, -1, 40, 40, 40, 40,
        40, 40, 40, -1, 40, 40, 40, 40);

      Special : array[0..63] of String =
        ('sll    ',#0       ,'srl    ','sra    ','sllv   ',#0       ,'srlv   ','srav   ',
         'jr     ','jalr   ',#0       ,#0       ,'syscall','break  ',#0       ,'sync   ',
         'mfhi   ','mthi   ','mflo   ','mtlo   ','dsllv  ',#0       ,'dsrlv  ','dsrav  ',
         'mult   ','multu  ','div    ','divu   ','dmult  ','dmultu ','ddiv   ','ddivu  ',
         'add    ','addu   ','sub    ','subu   ','and    ','or     ','xor    ','nor    ',
         #0       ,#0       ,'slt    ','sltu   ','dadd   ','daddu  ','dsub   ','dsubu  ',
         'tge    ','tgeu   ','tlt    ','tltu   ','teq    ',#0       ,'tne    ',#0       ,
         'dsll   ',#0       ,'dsrl   ','dsra   ','dsll32 ',#0       ,'dsrl32 ','dsra32 ');

      Special_Mode : array[0..63] of shortint =
        (  7, -1,  7,  7,  3, -1,  3,  3,
           9,  8, -1, -1,  0,  0, -1,  0,
          11, 12, 11, 12,  3, -1,  3,  3,
           6,  6,  6,  6,  6,  6,  6,  6,
           3,  3,  3,  3,  3,  3,  3,  3,
          -1, -1,  3,  3,  3,  3,  3,  3,
           6,  6,  6,  6,  6, -1,  6, -1,
           7, -1,  7,  7,  7, -1,  7,  7);

      Regimm : array[0..31] of String =
        ('bltz   ','bgez   ','bltzl  ','bgezl  ',#0       ,#0       ,#0       ,#0       ,
         'tgei   ','tgeiu  ','tlti   ','tltiu  ','teqi   ',#0       ,'tnei   ',#0       ,
         'bltzal ','bgezal ','bltzall','bgezall',#0       ,#0       ,#0       ,#0       ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        );

      Regimm_Mode : array[0..31] of shortint =
       ( 51, 51, 51, 51, -1, -1, -1, -1,
          5,  5,  5,  5,  5, -1,  5, -1,
         51, 51, 51, 51, -1, -1, -1, -1,
         -1, -1, -1, -1, -1, -1, -1, -1);

      CP0RS : array[0..15] of String =
        ('mfc0   ','dmfc0  ','cfc0   ',#0       ,'mtc0   ','dmtc0  ','ctc0   ',#0        ,
         'bc0    ',#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0         );

      CP0RT : array[0..31] of String =
        ('bc0f   ','bc0t   ','bc0fl  ','bc0tl  ',#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0         );

      CP0FUNC : array[0..63] of String =
        (#0       ,'tlbr   ','tlbwi  ',#0       ,#0       ,#0       ,'tlbwr  ',#0        ,
         'tlbp   ',#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         'eret   ',#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0         );

      CP1RS : array[0..31] of String =
        ('mfc1   ','dmfc1  ','cfc1   ',#0       ,'mtc1   ','dmtc1  ','ctc1   ',#0        ,
         'bc1    ',#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         's      ','d      ',#0       ,#0       ,'w      ','l      ',#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        );

      CP1RS_MODE : array[0..31] of shortint =
        (  1,  1,  1, -1,  1,  1,  1, -1,
           2, -1, -1, -1, -1, -1, -1, -1,
           3,  4, -1, -1,  5,  6, -1, -1,
          -1, -1, -1, -1, -1, -1, -1, -1);

      CP1RT : array[0..31] of String =
        ('bc1f   ','bc1t   ','bc1fl  ','bc1tl  ',#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0         );

      CP1RT_MODE : array[0..31] of shortint =
        (  1,  1,  1,  1, -1, -1, -1, -1,
          -1, -1, -1, -1, -1, -1, -1, -1,
          -1, -1, -1, -1, -1, -1, -1, -1,
          -1, -1, -1, -1, -1, -1, -1, -1);

      CP1FMTS : array[0..63] of String =
        ('add.s  ','sub.s  ','mul.s  ','div.s  ','sqrt.s ','abs.s  ','mov.s  ','neg.s   ',
         'round.l.s','trunc.l.s','ceil.l.s','floor.l.s','round.w.s','trunc.w.s','ceil.w.s','flour.w.s',
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         #0       ,'cvt.d.s',#0       ,#0       ,'cvt.w.s','cvt.l.s',#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         'c.f.s  ','c.un.s ','c.eq.s ','c.ueq.s','c.olt.s','c.ult.s','c.ole.s','c.ule.s ',
         'c.sf.s ','c.ngle.s','c.seq.s','c.ngl.s','c.lt.s ','c.nge.s','c.le.s ','c.ngt.s ');

      CP1FMTS_MODE : array[0..63] of shortint =
        (  1,  1,  1,  1,  1,  1,  1,  1,
           1,  1,  1,  1,  1,  1,  1,  1,
          -1, -1, -1, -1, -1, -1, -1, -1,
          -1, -1, -1, -1, -1, -1, -1, -1,
          -1,  1, -1, -1,  1,  1, -1, -1,
          -1, -1, -1, -1, -1, -1, -1, -1,
           1,  1,  1,  1,  1,  1,  1,  1,
           1,  1,  1,  1,  1,  1,  1,  1);

      CP1FMTD : array[0..63] of String =
        ('add.d  ','sub.d  ','mul.d  ','div.d  ','sqrt.d ','abs.d  ','mov.d  ','neg.d   ',
         'round.l.d','trunc.l.d','ceil.l.d','floor.l.d','round.w.d','trunc.w.d','ceil.w.d','flour.w.d',
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         'cvt.s.d',#0       ,#0       ,#0       ,'cvt.w.d','cvt.l.d',#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         'c.f.d  ','c.un.d ','c.eq.d ','c.ueq.d','c.olt.d','c.ult.d','c.ole.d','c.ule.d ',
         'c.sf.d ','c.ngle.d','c.seq.d','c.ngl.d','c.lt.d ','c.nge.d','c.le.d ','c.ngt.d ');

      CP1FMTD_MODE : array[0..63] of shortint =
        (  1,  1,  1,  1,  1,  1,  1,  1,
           1,  1,  1,  1,  1,  1,  1,  1,
          -1, -1, -1, -1, -1, -1, -1, -1,
          -1, -1, -1, -1, -1, -1, -1, -1,
           1, -1, -1, -1,  1,  1, -1, -1,
          -1, -1, -1, -1, -1, -1, -1, -1,
           1,  1,  1,  1,  1,  1,  1,  1,
           1,  1,  1,  1,  1,  1,  1,  1);

      CP1FMTW : array[0..63] of String =
        (#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         'cvt.s.w','cvt.d.w',#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        );

      CP1FMTW_MODE : array[0..63] of shortint =
        ( -1, -1, -1, -1, -1, -1, -1, -1,
          -1, -1, -1, -1, -1, -1, -1, -1,
          -1, -1, -1, -1, -1, -1, -1, -1,
          -1, -1, -1, -1, -1, -1, -1, -1,
           1,  1, -1, -1, -1, -1, -1, -1,
          -1, -1, -1, -1, -1, -1, -1, -1,
          -1, -1, -1, -1, -1, -1, -1, -1,
          -1, -1, -1, -1, -1, -1, -1, -1);

      CP1FMTL : array[0..63] of String =
        (#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         'cvt.s.l','cvt.d.l',#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        ,
         #0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0       ,#0        );

      CP1FMTL_MODE : array[0..63] of shortint =
        ( -1, -1, -1, -1, -1, -1, -1, -1,
          -1, -1, -1, -1, -1, -1, -1, -1,
          -1, -1, -1, -1, -1, -1, -1, -1,
          -1, -1, -1, -1, -1, -1, -1, -1,
           1,  1, -1, -1, -1, -1, -1, -1,
          -1, -1, -1, -1, -1, -1, -1, -1,
          -1, -1, -1, -1, -1, -1, -1, -1,
          -1, -1, -1, -1, -1, -1, -1, -1);

// ===========================================================================
//  Formatierungs Arten
// ===========================================================================
      Regs : array[0..1,0..31] of String =
        (('r00','r01','r02','r03','r04','r05','r06','r07',
          'r08','r09','r10','r11','r12','r13','r14','r15',
          'r16','r17','r18','r19','r20','r21','r22','r23',
          'r24','r25','r26','r27','r28','r29','r30','r31'),
         ('$zero','$at','$v0','$v1','$a0','$a1','$a2','$a3',
          '$t0','$t1','$t2','$t3','$t4','$t5','$t6','$t7',
          '$s0','$s1','$s2','$s3','$s4','$s5','$s6','$s7',
          '$t8','$t9','$k0','$k1','$gp','$sp','$fp','$ra'));

      CP0Regs : array[0..1,0..31] of String =
        (('c00','c01','c02','c03','c04','c05','c06','c07',
          'c08','c09','c10','c11','c12','c13','c14','c15',
          'c16','c17','c18','c19','c20','c21','c22','c23',
          'c24','c25','c26','c27','c28','c29','c30','c31'),
         ('Index','Random','EntryLo0','EntryLo1','Context','PageMask','Wired','Reserved',
          'BadVAddr','Count','EntryHi','Compare','SR','Cause','EPC','PRId',
          'Config','LLAddr','WatchLo','WatchHi','XContext','Reserved','Reserved','Reserved',
          'Reserved','Reserved','ECC','CacheErr','TagLo','TagHi','ErrorEPC','Reserved'));

      Farbe1 : Integer = 1;
      Farbe2 : Integer = 2;
      Farbe3 : Integer = 3;

type
  tDISASM = object
    BUFF  : DWORD;
    BASE  : DWORD;
    POS   : DWORD;
    COLOR : BYTE;
    procedure Init(BASED,POSD : DWORD);
    procedure Set_DA(POSD,DATA : DWORD);
    function Get_Opcode : Byte;         // All Types 6-bit operation code
    function Get_RS : Byte;             // I-Type & R-Type 5-bit source register
    function Get_RT : Byte;             // I-Type & R-Type 5-bit target register
    function Get_Immediate : Word;      // I-Type 16-bit immediate
    function Get_Target : DWORD;        // J-Type 26-bit jump target address
    function Get_RD : Byte;             // R-Type 5-bit destination register
    function Get_SA : Byte;             // R-Type 5-bit shift amount
    function Get_Funct : Byte;          // R-Type 6-bit function field
    function Get_Line : String;
    function Get_Color : Integer;
    function Get_Addr : DWORD;
    function Get_Tar : DWORD;
    function RS : String;
    function RT : String;
    function Immediate : String;
    function ImmediateSigned : String;
    function Target : String;
    function RD : String;
    function SA : String;
    function DW : String;
    function Offset : String;
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;


implementation

// ===========================================================================
//  Position und Data Uebergeben
// ===========================================================================
procedure tDISASM.Set_DA(POSD,DATA : DWORD);
begin
 BUFF := DATA;
 POS := BASE+POSD;
end;

// ===========================================================================
//  Position und Baseaddresse
// ===========================================================================
procedure tDISASM.Init(BASED,POSD : DWORD);
begin
 BASE := BASED;
 POS := POSD;
end;

// ===========================================================================
//  Functionen um Daten
// ===========================================================================
function tDISASM.Get_Funct : Byte;
begin
 Get_Funct := Buff and $3F;
end;
function tDISASM.Get_Opcode : Byte;
begin
 Get_Opcode := Buff and $FC000000 shr 26;
end;
function tDISASM.Get_Target : Dword;
begin
 Get_Target := Buff and $3FFFFFF;
end;
function tDISASM.Get_RS : Byte;
begin
 Get_RS := Buff and $3E00000 shr 21;
end;
function tDISASM.Get_RT : Byte;
begin
 Get_RT := Buff and $1F0000 shr 16;
end;
function tDISASM.Get_RD : Byte;
begin
 Get_RD := Buff and $F800 shr 11;
end;
function tDISASM.Get_Immediate : Word;
begin
 Get_Immediate := Buff and $FFFF;
end;
function tDISASM.Get_SA : Byte;
begin
 Get_SA := Buff and $7C0 shr 6;
end;

// ===========================================================================
//  Functionen um Daten in Strings Umzuwandeln
// ===========================================================================
function tDISASM.RS : String;
begin
 RS := Regs[1,Get_RS];
end;
function tDISASM.RT : String;
begin
 RT := Regs[1,Get_RT];
end;
function tDISASM.Target : String;
begin
 Target := '0x'+IntToHex((POS and $F0000000)+(Get_Target shl 2),8);
end;
function tDISASM.RD : String;
begin
 RD := Regs[1,Get_RD];
end;
function tDISASM.SA : String;
begin
 SA := IntToStr(Get_SA);
end;
function tDISASM.DW : String;
begin
 DW := 'dw 0x'+IntToStr(Get_SA);
end;
function tDISASM.Offset : String;
begin
 if Get_Immediate > $8000 then Offset := '0x'+IntToHex((Get_Immediate shl 2)+POS+4-$40000,8)
  else Offset := '0x'+IntToHex((Get_Immediate shl 2)+POS+4,8);
end;
function tDISASM.ImmediateSigned : String;
begin
 if (Get_Immediate > $8000) then ImmediateSigned := '-'+IntToStr(Get_Immediate-$8000)+'/0x'+IntToHex(Get_Immediate,4)
  else ImmediateSigned := IntToStr(Get_Immediate)+'/0x'+IntToHex(Get_Immediate,4);
end;
function tDISASM.Immediate : String;
begin
 Immediate := '0x'+IntToHex(Get_Immediate,4);
end;

function tDISASM.Get_Color : Integer;
begin
 Get_Color := COLOR;
end;

function tDISASM.Get_Addr : DWORD;
begin
 if Get_Immediate > $8000 then Get_Addr := (Get_Immediate shl 2)+POS+4-$40000
  else Get_Addr := (Get_Immediate shl 2)+POS+4;
end;

function tDISASM.Get_Tar : DWORD;
begin
 Get_Tar := (POS and $F0000000)+(Get_Target shl 2);
end;

// ===========================================================================
//  Function um Disasm String zubekommen
// ===========================================================================
function tDISASM.Get_Line : String;
var Temp : String;
begin
 COLOR := 0;
 if BUFF = 0 then Temp := 'nop' else
 case Opcode_Mode[Get_Opcode] of
   -1 : Temp := DW;
    2 : begin
         Temp := Opcode[Get_Opcode]+Target;
         COLOR := Farbe2;
        end;
    4 : Temp := Opcode[Get_Opcode]+RT+','+RS+','+Immediate;
    5 : Temp := Opcode[Get_Opcode]+RT+','+RS+','+ImmediateSigned;
   10 : Temp := Opcode[Get_Opcode]+RT+','+Immediate;
   40 : Temp := Opcode[Get_Opcode]+RT+','+Immediate+'('+RS+')';
   50 : begin
         Temp := Opcode[Get_Opcode]+RT+','+RS+','+Offset;
         COLOR := Farbe1;
        end;
   51 : begin
         Temp := Opcode[Get_Opcode]+RS+','+Offset;
         COLOR := Farbe1;
        end;
  100 : Case Special_Mode[Get_Funct] of
          -1 : Temp := DW;
           3 : Temp := Special[Get_Funct]+RD+','+RS+','+RT;
           6 : Temp := Special[Get_Funct]+RT+','+RS;
           7 : Temp := Special[Get_Funct]+RD+','+RT+','+SA;
           8 : begin
                Temp := Special[Get_Funct]+RD+','+RS;
                COLOR := Farbe3;
               end;
           9 : begin
                Temp := Special[Get_Funct]+RS;
                COLOR := Farbe3;
               end;
          11 : Temp := Special[Get_Funct]+RD;
          12 : Temp := Special[Get_Funct]+RS;
        end;
  101 : Case Regimm_Mode[Get_RT] of
          -1 : Temp := DW;
           5 : Temp := Regimm[Get_RT]+RS+' '+Immediate;
          51 : begin
                Temp := Regimm[Get_RT]+RS+' '+Offset;
                Color := Farbe1;
               end;
        end;
 // COP 0
  102 : Case Get_RS of
           0 : if CP0Func[Get_SA] <> #0 then Temp := CP0Func[Get_SA];
           8 : Temp := CP0RT[Get_RT]+Immediate;
          else Temp := CP0RS[Get_RS]+RT+','+CP0Regs[1,Get_RD];
        end;
 // COP 1
  103 : Case CP1RS_MODE[Get_RS] of
           1 : Temp := CP1RS[Get_RS]+RT+','+CP0Regs[0,Get_RD];
           2 : if CP1RT_MODE[Get_RT] = 1 then
                begin
                 Temp := CP1RT[Get_RT]+Offset;
                 COLOR := Farbe1;
                end
                else Temp := DW;
           3 : if CP1FMTS_MODE[Get_Funct] = 1 then Temp := CP1FMTS[Get_Funct]
                else Temp := DW;
           4 : if CP1FMTD_MODE[Get_Funct] = 1 then Temp := CP1FMTD[Get_Funct]
                else Temp := DW;
           5 : if CP1FMTW_MODE[Get_Funct] = 1 then Temp := CP1FMTW[Get_Funct]
                else Temp := DW;
           6 : if CP1FMTL_MODE[Get_Funct] = 1 then Temp := CP1FMTL[Get_Funct]
                else Temp := DW;
          -1 : Temp := DW;
        end;
 // COP 2
  104 : begin
        end;
 // Cache Instructions
  105 : begin
         Temp := 'cache  0x'+IntToHex(Get_RT,2)+','+Immediate+'('+RS+')';
        end;
 end;
 Get_Line := '0x'+IntToHex(POS,8)+' '+Temp;
end;

end.
