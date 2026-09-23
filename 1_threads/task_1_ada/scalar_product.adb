with Ada.Text_IO;              use Ada.Text_IO;
with Ada.Numerics.Float_Random;
with Ada.Real_Time;            use Ada.Real_Time;

procedure Scalar_Product is
   N : constant := 1_000_000;  -- длина векторов
   T : constant := 4;           -- число задач

   type Vector is array (Positive range <>) of Float;
   A, B : Vector (1 .. N);

   Gen : Ada.Numerics.Float_Random.Generator;

   task type Worker is
      entry Start (First, Last : Integer);
      entry Get_Result (Sum : out Float);
   end Worker;

   task body Worker is
      My_First, My_Last : Integer;
      Local_Sum : Float := 0.0;
   begin
      accept Start (First, Last : Integer) do
         My_First := First;
         My_Last  := Last;
      end Start;

      for I in My_First .. My_Last loop
         Local_Sum := Local_Sum + A (I) * B (I);
      end loop;

      accept Get_Result (Sum : out Float) do
         Sum := Local_Sum;
      end Get_Result;
   end Worker;

   Workers : array (1 .. T) of Worker;

   Seq_Sum, Par_Sum : Float := 0.0;
   Block, First, Last : Integer;
   T0, T1 : Time;
   Elapsed : Duration;

   procedure Print_Result (Label : String; Sum : Float; El : Duration) is
   begin
      Put_Line (Label & ": sum = " & Float'Image (Sum) &
                ", time = " & Duration'Image (El) & " s");
   end Print_Result;

begin
   Ada.Numerics.Float_Random.Reset (Gen, 42);
   for I in 1 .. N loop
      A (I) := Ada.Numerics.Float_Random.Random (Gen);
      B (I) := Ada.Numerics.Float_Random.Random (Gen);
   end loop;

   T0 := Clock;
   for I in 1 .. N loop
      Seq_Sum := Seq_Sum + A (I) * B (I);
   end loop;
   T1 := Clock;
   Elapsed := To_Duration (T1 - T0);
   Print_Result ("Sequential", Seq_Sum, Elapsed);

   Block := N / T;

   T0 := Clock;
   for I in 1 .. T loop
      First := (I - 1) * Block + 1;
      Last  := (if I = T then N else I * Block);
      Workers (I).Start (First, Last);
   end loop;

   for I in 1 .. T loop
      declare
         S : Float;
      begin
         Workers (I).Get_Result (S);
         Par_Sum := Par_Sum + S;
      end;
   end loop;
   T1 := Clock;
   Elapsed := To_Duration (T1 - T0);
   Print_Result ("Parallel  ", Par_Sum, Elapsed);
   Put_Line ("Tasks: " & Integer'Image (T));
end Scalar_Product;