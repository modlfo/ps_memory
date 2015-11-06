
let create (cmd:string) (args:string list) : int =
   try
      Unix.create_process cmd
         (cmd::args |> Array.of_list)
         Unix.stdin Unix.stdout Unix.stderr
   with _ -> failwith "Cannot create the process"

let isRunning (pid:int) : bool =
   match Unix.waitpid [Unix.WNOHANG] pid with
   | 0,_ -> true
   | p,Unix.WEXITED(ret) when p = pid -> false
   | p,Unix.WSIGNALED(_) when p = pid -> false
   | p,Unix.WSTOPPED(_)  when p = pid -> false
   | _ -> false
   | exception _ -> false

let sample (pid:int) : int =
   let input_mine, input_theirs = Unix.pipe () in
   let result = ref "" in
   let pid =
      try
         let cmd = "ps" in
         let args = ["-o"; "rss"; string_of_int pid] in
      Unix.create_process cmd
         (cmd::args |> Array.of_list)
         Unix.stdin input_theirs Unix.stderr
      with | _ -> failwith "Could not call 'ps'"
   in
   Unix.close input_theirs;
   let input_channel = Unix.in_channel_of_descr input_mine in
   begin
      try
         let i = ref 0 in
         while true do
            let current = input_line input_channel in
            if !i = 1 then
               result := current;
            incr i;
         done
      with _ -> ()
   end;
   Unix.close input_mine;
   match Unix.waitpid [] pid with
   | _, Unix.WEXITED(ret) -> String.trim !result |> int_of_string
   | _ -> String.trim !result |> int_of_string


let writeSamples (samples:int list) : unit =
   let oc = open_out "ps_memory.out" in
   let rec iter l =
      match l with
      | []   -> ()
      | [n]  -> Printf.fprintf oc "%i" n
      | n::t ->
         Printf.fprintf oc "%i, " n;
         iter t
   in
   Printf.fprintf oc "{ ";
   iter samples;
   Printf.fprintf oc "}"

let () =
   match Array.to_list Sys.argv with
   | _::cmd::args ->
      let pid = create cmd args in
      let samples = ref [] in
      while isRunning pid do
         let current = sample pid in
         samples := current :: !samples;
         Unix.sleep 1
      done;
      writeSamples (List.rev !samples)

   | _ -> failwith "Invalid input"
