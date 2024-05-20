export interface Member {
  id: number;
  name: string;
}

export interface Members {
  leader: Member;
  helpers: Member[];
}

export interface Group {
  id: number;
  displayName: string;
  status?: string;
  members: Members;
  isLeader: boolean;
}

export interface Request {
  id: number;
  name: string;
}
