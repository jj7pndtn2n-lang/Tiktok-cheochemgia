-- Moon Hunt: lưu nhân vật đã chọn và điểm cao nhất để rơi lưỡi liềm khi tử trận.
alter table public.game_players
  add column if not exists character_index integer not null default 0;

alter table public.game_players
  add column if not exists max_score integer not null default 1;

do $$ begin
  alter publication supabase_realtime add table public.game_players;
exception when duplicate_object then null;
end $$;
