from pathlib import Path
from PIL import Image, ImageFilter, ImageDraw
import numpy as np, heapq, math, json
# Extract navigation geometry only; the approved image is copied unmodified.
im=Image.open('game/assets/arena.png').convert('RGB'); w,h=im.size
rgb=np.asarray(im).astype(float); r,g,b=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
ground=(r>90)&(r>g*.94)&(g>b*1.17)
ground_image=Image.fromarray((ground*255).astype('uint8')).filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.MinFilter(9))
# Pale paving and its blue decorative inlay are walkable in the two bases.
draw=ImageDraw.Draw(ground_image)
draw.polygon([(105,1050),(80,980),(100,870),(135,790),(210,795),(280,865),(330,970),(250,1030)],fill=255)
draw.polygon([(1050,180),(1095,100),(1180,55),(1200,110),(1170,240),(1100,225)],fill=255)
# Open dirt clearing in shadow at the lower-right jungle entrance.
draw.polygon([(1025,650),(1100,645),(1100,675),(1050,685),(1025,670)], fill=255)
# Explicit rock silhouettes: warm highlights must not be classified as floor.
for polygon in [
    [(625,800),(650,800),(675,840),(675,875),(655,900),(635,875),(625,840)],
    [(470,730),(495,720),(525,740),(520,770),(490,770)],
    [(340,790),(370,800),(395,850),(395,910),(365,935),(350,900)],
    [(860,765),(885,765),(900,810),(885,850),(860,845),(845,810)],
]: draw.polygon(polygon, fill=0)
mask=np.asarray(ground_image.filter(ImageFilter.MinFilter(7)))>0
step=5
walk=mask[::step,::step]; H,W=walk.shape
# Explicit visual landmarks in source-image pixels. Ground extraction keeps
# routes away from dark foliage and grey rock; inspect the overlay after edits.
# Keep the connected terrain, excluding isolated foliage highlights.
seen=set(); largest=[]
for yy,xx in zip(*np.where(walk)):
    seed=(int(xx),int(yy))
    if seed in seen: continue
    stack=[seed];seen.add(seed);component=[]
    while stack:
        x,y=stack.pop();component.append((x,y))
        for dx,dy in [(1,0),(-1,0),(0,1),(0,-1)]:
            q=(x+dx,y+dy)
            if 0<=q[0]<W and 0<=q[1]<H and walk[q[1],q[0]] and q not in seen:
                seen.add(q);stack.append(q)
    if len(component)>len(largest):largest=component
walk[:]=False
for x,y in largest:walk[y,x]=True
base=[(150,990),(1150,100)]
camps=[[(625,1000),(700,870),(590,775),(315,610),(245,440),(450,535)],[(1065,670),(960,490),(1030,320),(680,225),(545,285),(420,170)]]
def snap(p):
    ys,xs=np.where(walk); k=np.argmin((xs*step-p[0])**2+(ys*step-p[1])**2)
    q=(int(xs[k]),int(ys[k])); print('snap',p,'=>',(q[0]*step,q[1]*step),'distance',round(math.dist(p,(q[0]*step,q[1]*step)),1))
    return q
B=[snap(p) for p in base]; C=[[snap(p) for p in team] for team in camps]
dirs=[(1,0),(-1,0),(0,1),(0,-1),(1,1),(1,-1),(-1,1),(-1,-1)]
def astar(a,z):
    heap=[(0,a)]; dist={a:0}; prev={}
    while heap:
        _,p=heapq.heappop(heap)
        if p==z:
            out=[p]
            while p in prev: p=prev[p];out.append(p)
            return out[::-1]
        for dx,dy in dirs:
            q=(p[0]+dx,p[1]+dy);x,y=q
            if not (0<=x<W and 0<=y<H and walk[y,x]):continue
            if dx and dy and (not walk[p[1],x] or not walk[y,p[0]]):continue
            nd=dist[p]+math.hypot(dx,dy)
            if nd<dist.get(q,float('inf')):
                dist[q]=nd;prev[q]=p;heapq.heappush(heap,(nd+math.dist(q,z),q))
    raise ValueError(f'No ground path {a}->{z}')
def through(points):
    out=[]
    for a,b in zip(points,points[1:]):out.extend(astar(a,b)[:-1])
    return out+[points[-1]]
lanes=[through([B[0]]+[snap(p) for p in [(125,740),(125,360),(180,190),(365,110),(680,118),(980,125)]]+[B[1]]),through([B[0]]+[snap(p) for p in [(365,755),(490,635),(615,510),(860,300),(980,220)]]+[B[1]]),through([B[0]]+[snap(p) for p in [(470,1025),(860,1040),(1110,960),(1150,700),(1140,380),(1145,230)]]+[B[1]])]
paths=list(lanes)
for team in range(2):
    paths.append(through([B[team]]+C[team]))
    # Each camp has an exit to the nearest lane; the pathfinder uses only
    # connected ground, even when the straight-line destination is nearby.
    for c in C[team]:
        for lane in lanes:
            closest=min(lane,key=lambda p:math.dist(p,c))
            paths.append(astar(c,closest))
# Add the river and pit floors only after generating the original lane/camp
# paths. Blue water is walkable; rock silhouettes and foliage remain blocked.
river_region=Image.new('L', (w,h))
ImageDraw.Draw(river_region).polygon([(230,210),(560,225),(635,450),(720,560),
    (1085,730),(1110,915),(820,930),(775,765),(590,640),(330,480)],fill=255)
water=(b>r*1.1)&(g>r*1.08)&(g>65)&(np.asarray(river_region)>0)
river_floor=Image.fromarray((((np.asarray(ground_image)>0) | water)*255).astype('uint8'))
river_floor=river_floor.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.MinFilter(9)).filter(ImageFilter.MinFilter(7))
walk |= (np.asarray(river_floor)>0)[::step,::step] & (np.asarray(river_region)>0)[::step,::step]
# Keep only floor reachable from the existing lanes, including shallow shores.
reachable=set(); stack=[B[0]]
while stack:
    p=stack.pop()
    if p in reachable: continue
    reachable.add(p)
    for dx,dy in dirs[:4]:
        q=(p[0]+dx,p[1]+dy)
        if 0<=q[0]<W and 0<=q[1]<H and walk[q[1],q[0]] and q not in reachable:
            stack.append(q)
walk[:]=False
for x,y in reachable: walk[y,x]=True

objectives={}
for key,anchor in [('baron',(495,285)),('dragon',(890,855))]:
    center=snap(anchor)
    # Every role keeps its own destination even when another participant dies.
    # Choose actual floor around the pit, with room for individual health bars.
    candidates=[p for p in sorted(reachable) if 80<=math.dist(p,center)*step<=155]
    positions=[]
    for team in range(2):
        for slot in range(5):
            angle=math.radians(110+slot*32+team*180)
            ideal=(center[0]+23*math.cos(angle),center[1]+23*math.sin(angle))
            available=[p for p in candidates if all(math.dist(p,q)*step>=60 for q in positions)]
            if not available: raise ValueError(f'No separated objective slot: {key} {team} {slot}')
            point=min(available,key=lambda p:(math.dist(p,ideal),p))
            positions.append(point)
            paths.append(astar(center,point))
            # Approach each role's spot directly instead of funneling the whole
            # team through the monster's center before spreading out.
            for lane in lanes:
                paths.append(astar(point,min(lane,key=lambda p:math.dist(p,point))))
    for lane in lanes:
        paths.append(astar(center,min(lane,key=lambda p:math.dist(p,center))))
    objectives[key]={'center':center,'positions':positions}
ids={};nodes=[];edges=set()
def ident(p):
    if p not in ids:ids[p]=len(nodes);nodes.append([p[0]*step/w,p[1]*step/h])
    return ids[p]
for path in paths:
    for a,b in zip(path,path[1:]): edges.add(tuple(sorted((ident(a),ident(b)))))
data={'source_size':[w,h],'clearance_pixels':5,'nodes':nodes,'edges':sorted(edges),'lanes':[[ident(p) for p in lane] for lane in lanes],'camps':[[ident(p) for p in team] for team in C],'bases':[ident(p) for p in B]}
data['objectives']={key:{'center':ident(value['center']),
    'positions':[ident(p) for p in value['positions']]} for key,value in objectives.items()}
Path('game/assets/arena_navigation.json').write_text(json.dumps(data,separators=(',',':')))
print('Navigation:',len(nodes),'nodes',len(edges),'edges')


