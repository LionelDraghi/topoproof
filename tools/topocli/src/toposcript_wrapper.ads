-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

--  Generation of the hidden Ada compilation-unit wrapper around a
--  TopoScript source (development plan, Milestone 6, Increment 2).
--
--  A TopoScript fragment contains declarations and executable
--  statements, without compilation-unit boilerplate:
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
--
--  The wrapper places the fragment, it does not judge it (DD-003,
--  2026-10-24): it neither analyses the syntax nor the semantics, and
--  it never rejects a fragment. The accepted subset is everything HAC
--  handles: the wrapper only locates the boundary between the
--  declarations and the statements, and a line it does not recognise
--  as a declaration goes to the statement region, unless the text
--  from that line to its first ';' assembles into a declaration form
--  (a declaration split across lines stays in the declarative part).
--  A misplacement surfaces as a HAC diagnostic, mapped back to the
--  fragment line by TopoScript_Diagnostics.

with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings.Unbounded;

package TopoScript_Wrapper is

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
      Result   : out Wrapped_Source);
   --  Split the fragment into a declaration region and a statement
   --  region, and build the wrapped compilation unit. The wrapper
   --  places the fragment and never rejects it: the recognised
   --  declaration forms, their continuations, the constructs that
   --  assemble into a declaration form up to their first ';', and the
   --  content of a nested unit body go to the declarative part, and
   --  everything else goes to the body (DD-003, 2026-10-24). The
   --  fragment path is not Generate's concern: the diagnostics pipe
   --  takes it through Set_Mapping.

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
