/*
 * $Id: i_keybd.ch,v 1.4 2006-02-25 04:07:28 guerra000 Exp $
 */
/*
 * ooHG source code:
 * Keyboard handling definitions
 *
 * Copyright 2005 Vicente Guerra <vicente@guerra.com.mx>
 * www - http://www.guerra.com.mx
 *
 * Portions of this code are copyrighted by the Harbour MiniGUI library.
 * Copyright 2002-2005 Roberto Lopez <roblez@ciudad.com.ar>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307 USA (or visit the web site http://www.gnu.org/).
 *
 * As a special exception, the ooHG Project gives permission for
 * additional uses of the text contained in its release of ooHG.
 *
 * The exception is that, if you link the ooHG libraries with other
 * files to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the ooHG library code into it.
 *
 * This exception does not however invalidate any other reasons why
 * the executable file might be covered by the GNU General Public License.
 *
 * This exception applies only to the code released by the ooHG
 * Project under the name ooHG. If you copy code from other
 * ooHG Project or Free Software Foundation releases into a copy of
 * ooHG, as the General Public License permits, the exception does
 * not apply to the code that you add in this way. To avoid misleading
 * anyone as to the status of such modified files, you must delete
 * this exception notice from them.
 *
 * If you write modifications of your own for ooHG, it is your choice
 * whether to permit this exception to apply to your modifications.
 * If you do not wish that, delete this exception notice.
 *
 */
/*----------------------------------------------------------------------------
 MINIGUI - Harbour Win32 GUI library source code

 Copyright 2002-2005 Roberto Lopez <roblez@ciudad.com.ar>
 http://www.geocities.com/harbour_minigui/

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version.

 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

 You should have received a copy of the GNU General Public License along with
 this software; see the file COPYING. If not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA (or
 visit the web site http://www.gnu.org/).

 As a special exception, you have permission for additional uses of the text
 contained in this release of Harbour Minigui.

 The exception is that, if you link the Harbour Minigui library with other
 files to produce an executable, this does not by itself cause the resulting
 executable to be covered by the GNU General Public License.
 Your use of that executable is in no way restricted on account of linking the
 Harbour-Minigui library code into it.

 Parts of this project are based upon:

        "Harbour GUI framework for Win32"
        Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
        Copyright 2001 Antonio Linares <alinares@fivetech.com>
        www - http://www.harbour-project.org

        "Harbour Project"
        Copyright 1999-2003, http://www.harbour-project.org/
---------------------------------------------------------------------------*/

///////////////////////////////////////////////////////////////////////////////
// InteractiveClose
///////////////////////////////////////////////////////////////////////////////

#xcommand SET INTERACTIVECLOSE OFF ;
=> ;
SetInteractiveClose( 0 )

#xcommand SET INTERACTIVECLOSE ON ;
=> ;
SetInteractiveClose( 1 )

#xcommand SET INTERACTIVECLOSE QUERY;
=> ;
SetInteractiveClose( 2 )

#xcommand SET INTERACTIVECLOSE QUERY MAIN ;
=> ;
SetInteractiveClose( 3 )



#xtranslate SET NAVIGATION EXTENDED ;
=> ;
_OOHG_ExtendedNavigation := .T.

#xtranslate SET NAVIGATION STANDARD ;
=> ;
_OOHG_ExtendedNavigation := .F.

///////////////////////////////////////////////////////////////////////////////
// Virtual key Codes And Modifiers
///////////////////////////////////////////////////////////////////////////////

#define VK_LBUTTON	1
#define VK_RBUTTON	2
#define VK_CANCEL	3
#define VK_MBUTTON	4
#define VK_BACK	8
#define VK_TAB	9
#define VK_CLEAR	12
#define VK_RETURN	13
#define VK_SHIFT	16
#define VK_CONTROL	17
#define VK_MENU	18
#define VK_PAUSE	19
#define VK_PRINT	42
#define VK_CAPITAL	20
#define VK_KANA	0x15
#define VK_HANGEUL	0x15
#define VK_HANGUL	0x15
#define VK_JUNJA	0x17
#define VK_FINAL	0x18
#define VK_HANJA	0x19
#define VK_KANJI	0x19
#define VK_CONVERT	0x1C
#define VK_NONCONVERT	0x1D
#define VK_ACCEPT	0x1E
#define VK_MODECHANGE	0x1F
#define VK_ESCAPE	27
#define VK_SPACE	32
#define VK_PRIOR	33
#define VK_NEXT	34
#define VK_END	35
#define VK_HOME	36
#define VK_LEFT	37
#define VK_UP	38
#define VK_RIGHT	39
#define VK_DOWN	40
#define VK_SELECT	41
#define VK_EXECUTE	43
#define VK_SNAPSHOT	44
#define VK_INSERT	45
#define VK_DELETE	46
#define VK_HELP	47
#define VK_0	48
#define VK_1	49
#define VK_2	50
#define VK_3	51
#define VK_4	52
#define VK_5	53
#define VK_6	54
#define VK_7	55
#define VK_8	56
#define VK_9	57
#define VK_A	65
#define VK_B	66
#define VK_C	67
#define VK_D	68
#define VK_E	69
#define VK_F	70
#define VK_G	71
#define VK_H	72
#define VK_I	73
#define VK_J	74
#define VK_K	75
#define VK_L	76
#define VK_M	77
#define VK_N	78
#define VK_O	79
#define VK_P	80
#define VK_Q	81
#define VK_R	82
#define VK_S	83
#define VK_T	84
#define VK_U	85
#define VK_V	86
#define VK_W	87
#define VK_X	88
#define VK_Y	89
#define VK_Z	90
#define VK_LWIN	0x5B
#define VK_RWIN	0x5C
#define VK_APPS	0x5D
#define VK_NUMPAD0	96
#define VK_NUMPAD1	97
#define VK_NUMPAD2	98
#define VK_NUMPAD3	99
#define VK_NUMPAD4	100
#define VK_NUMPAD5	101
#define VK_NUMPAD6	102
#define VK_NUMPAD7	103
#define VK_NUMPAD8	104
#define VK_NUMPAD9	105
#define VK_MULTIPLY	106
#define VK_ADD	107
#define VK_SEPARATOR	108
#define VK_SUBTRACT	109
#define VK_DECIMAL	110
#define VK_DIVIDE	111
#define VK_F1	112
#define VK_F2	113
#define VK_F3	114
#define VK_F4	115
#define VK_F5	116
#define VK_F6	117
#define VK_F7	118
#define VK_F8	119
#define VK_F9	120
#define VK_F10	121
#define VK_F11	122
#define VK_F12	123
#define VK_F13	124
#define VK_F14	125
#define VK_F15	126
#define VK_F16	127
#define VK_F17	128
#define VK_F18	129
#define VK_F19	130
#define VK_F20	131
#define VK_F21	132
#define VK_F22	133
#define VK_F23	134
#define VK_F24	135
#define VK_NUMLOCK	144
#define VK_SCROLL	145
#define VK_LSHIFT	160
#define VK_LCONTROL	162
#define VK_LMENU	164
#define VK_RSHIFT	161
#define VK_RCONTROL	163
#define VK_RMENU	165
#define VK_PROCESSKEY	229

#define VK_OEM_1        0xBA
#define VK_OEM_PLUS     0xBB
#define VK_OEM_COMMA    0xBC
#define VK_OEM_MINUS    0xBD
#define VK_OEM_PERIOD   0xBE
#define VK_OEM_2        0xBF
#define VK_OEM_3        0xC0

#define MOD_ALT         1
#define MOD_CONTROL	2
#define MOD_SHIFT	4
#define MOD_WIN         8

// End

#xcommand ON KEY <key> [ OF <parent> ] ACTION <action> ;
          => ;
          _DefineAnyKey( <(parent)>, <(key)>, <{action}> )

#xcommand RELEASE KEY <key> OF <parent> ;
          => ;
          _DefineAnyKey( <(parent)>, <(key)>, nil )

#xcommand STORE KEY <key> OF <parent> TO <baction> ;
          => ;
          <baction> := _DefineAnyKey( <(parent)>, <(key)> )

///////////////////////////////////////////////////////////////////////////////
// PUSH KEY COMMAND
///////////////////////////////////////////////////////////////////////////////
/*
#xcommand PUSH KEY F1 ;
=> ;
_PushKey ( VK_F1 )

#xcommand PUSH KEY F2  ;
=> ;
_PushKey ( VK_F2 )

#xcommand PUSH KEY F3  ;
=> ;
_PushKey ( VK_F3 )

#xcommand PUSH KEY F4 ;
=> ;
_PushKey ( VK_F4 )

#xcommand PUSH KEY F5 ;
=> ;
_PushKey ( VK_F5 )

#xcommand PUSH KEY F6 ;
=> ;
_PushKey ( VK_F6 )

#xcommand PUSH KEY F7 ;
=> ;
_PushKey ( VK_F7 )

#xcommand PUSH KEY F8 ;
=> ;
_PushKey ( VK_F8 )

#xcommand PUSH KEY F9 ;
=> ;
_PushKey ( VK_F9 )

#xcommand PUSH KEY F10  ;
=> ;
_PushKey ( VK_F10 )

#xcommand PUSH KEY F11  ;
=> ;
_PushKey ( VK_F11 )

#xcommand PUSH KEY F12 ;
=> ;
_PushKey ( VK_F12 )

#xcommand PUSH KEY BACK ;
=> ;
_PushKey ( VK_BACK )

#xcommand PUSH KEY TAB ;
=> ;
_PushKey ( VK_TAB )

#xcommand PUSH KEY RETURN ;
=> ;
_PushKey ( VK_RETURN )

#xcommand PUSH KEY ESCAPE ;
=> ;
_PushKey ( VK_ESCAPE )

#xcommand PUSH KEY SPACE ;
=> ;
_PushKey ( VK_SPACE )

#xcommand PUSH KEY END ;
=> ;
_PushKey ( VK_END )

#xcommand PUSH KEY HOME ;
=> ;
_PushKey ( VK_HOME )

#xcommand PUSH KEY LEFT ;
=> ;
_PushKey ( VK_LEFT )

#xcommand PUSH KEY UP ;
=> ;
_PushKey ( VK_UP  )

#xcommand PUSH KEY RIGHT ;
=> ;
_PushKey ( VK_RIGHT )

#xcommand PUSH KEY DOWN ;
=> ;
_PushKey ( VK_DOWN )

#xcommand PUSH KEY INSERT ;
=> ;
_PushKey ( VK_INSERT )

#xcommand PUSH KEY DELETE ;
=> ;
_PushKey ( VK_DELETE )

#xcommand PUSH KEY PRIOR ;
=> ;
_PushKey ( VK_PRIOR )

#xcommand PUSH KEY NEXT ;
=> ;
_PushKey ( VK_NEXT )

#xcommand PUSH KEY CAPSLOCK ;
=> ;
_PushKey ( VK_CAPITAL )

#xcommand PUSH KEY SCROLLLOCK ;
=> ;
_PushKey ( VK_SCROLL )

#xcommand PUSH KEY NUMLOCK ;
=> ;
_PushKey ( VK_NUMLOCK )
*/