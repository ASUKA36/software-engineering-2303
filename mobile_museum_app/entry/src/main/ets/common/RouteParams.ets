export interface ArtifactRouteParams {
  museumId: string;
  objectId: string;
}

export function buildArtifactRouteParams(museumId: number, objectId: string): ArtifactRouteParams {
  const p: ArtifactRouteParams = {
    museumId: `${museumId}`,
    objectId: objectId
  };
  return p;
}
