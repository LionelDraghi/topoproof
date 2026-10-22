-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

--  Generation of the hidden Ada compilation-unit wrapper around a
--  TopoScript source (development plan, Milestone 6, Increment 2).
--
--  A TopoScript fragment contains object declarations followed by
--  executable statements, without compilation-unit boilerplate:
--
--     P      : constant Point_3D := (10, -20, 30);
--     D      : constant Vector_3D := (5, 7, -9);
--     Result : Point_3D;
--
--     Translate (P, D, Result);
--
--     Put (Result);
--
--  Generate inserts the declarations into the declarative part of a
--  generated main procedure, and the statements into its body, between
--  the injected scripting API and the closing end. The line offsets of
--  the two regions are returned with the source, so that compilation
--  diagnostics can be mapped back to the fragment.

with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings.Unbounded;

package TopoScript_Wrapper is

   Wrapper_Error : exception;
   --  Raised by Generate, with a message of the form
   --  "error: FILE:LINE: ...", already ready for standard error.

   type Wrapped_Source is record
      Source           : Ada.Strings.Unbounded.Unbounded_String;
      --  The complete compilation unit, ending with a line feed.
      Declaration_Skip : Positive;
      --  Wrapper lines before the first fragment line: a diagnostic on
      --  wrapper line L before the begin refers to fragment line
      --  L - Declaration_Skip.
      Begin_Line       : Positive;
      --  The wrapper line holding the begin keyword.
      Statement_Adjust : Positive;
      --  Wrapper line offset of the statement region: a diagnostic on
      --  wrapper line L from the begin on refers to fragment line
      --  L - Statement_Adjust.
   end record;

   procedure Generate
     (Fragment :     String;
      Path     :     String;
      Result   : out Wrapped_Source);
   --  Split the fragment into a declaration region and a statement
   --  region, and build the wrapped compilation unit. Declarations
   --  must precede the first executable statement, and the initial
   --  subset accepts object declarations only: anything else raises
   --  Wrapper_Error.

   --  In-memory source stream, consumed by HAC through the standard
   --  Ada stream interface: an empty read reports the end of the
   --  stream, which is the convention the HAC scanner expects. The
   --  stream lives at library level, because HAC keeps a library-level
   --  access to it: one tool run wraps exactly one source.

   procedure Set_Source (Content : String);
   --  Make the wrapped source the content of the in-memory stream.

   function Stream return Ada.Streams.Stream_IO.Stream_Access;
   --  The stream access to pass to HAC's Set_Main_Source_Stream, after
   --  Set_Source.

private

   type String_Access is access all String;

   type Memory_Stream is
     new Ada.Streams.Root_Stream_Type with record
        Data : access constant String := null;
        Pos  : Natural := 0;
     end record;

   procedure Open
     (S    : in out Memory_Stream;
      Data : not null access constant String);

   overriding procedure Read
     (S    : in out Memory_Stream;
      Item :    out Ada.Streams.Stream_Element_Array;
      Last :    out Ada.Streams.Stream_Element_Offset);

   overriding procedure Write
     (S    : in out Memory_Stream;
      Item :        Ada.Streams.Stream_Element_Array);

end TopoScript_Wrapper;
